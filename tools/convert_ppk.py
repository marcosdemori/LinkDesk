import sys
import os
import stat
import base64
import struct

def convert_ppk(ppk_path, out_path=None):
    if not out_path:
        out_path = os.path.splitext(ppk_path)[0] + ".key"
    
    with open(ppk_path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = [line.strip() for line in f.readlines()]
    
    enc = None
    pub_b64 = ''
    priv_b64 = ''
    state = None
    algo = 'ssh-rsa'
    
    for line in lines:
        if line.startswith('PuTTY-User-Key-File'):
            algo = line.split(':')[1].strip()
        elif line.startswith('Encryption:'):
            enc = line.split(':')[1].strip()
        elif line.startswith('Public-Lines:'):
            state = 'pub'
        elif line.startswith('Private-Lines:'):
            state = 'priv'
        elif line.startswith('Private-MAC:'):
            state = None
        elif state == 'pub':
            pub_b64 += line
        elif state == 'priv':
            priv_b64 += line
            
    if enc != 'none':
        print(f"[!] Chave PPK protegida por senha. Nao e possivel converter automaticamente sem senha.")
        return None

    try:
        from cryptography.hazmat.primitives.asymmetric import rsa
        from cryptography.hazmat.primitives import serialization

        pub_bytes = base64.b64decode(pub_b64)
        priv_bytes = base64.b64decode(priv_b64)

        def read_mpint(b, offset):
            length = struct.unpack('>I', b[offset:offset+4])[0]
            offset += 4
            val = int.from_bytes(b[offset:offset+length], byteorder='big')
            return val, offset + length

        def read_string(b, offset):
            length = struct.unpack('>I', b[offset:offset+4])[0]
            offset += 4
            return b[offset:offset+length], offset + length

        # Parse public
        _, off = read_string(pub_bytes, 0)
        e, off = read_mpint(pub_bytes, off)
        n, _ = read_mpint(pub_bytes, off)

        # Parse private
        d, off2 = read_mpint(priv_bytes, 0)
        p, off2 = read_mpint(priv_bytes, off2)
        q, off2 = read_mpint(priv_bytes, off2)
        iqmp, _ = read_mpint(priv_bytes, off2)

        dmp1 = d % (p - 1)
        dmq1 = d % (q - 1)

        pub_nums = rsa.RSAPublicNumbers(e, n)
        priv_nums = rsa.RSAPrivateNumbers(p, q, d, dmp1, dmq1, iqmp, pub_nums)
        key = priv_nums.private_key()

        pem = key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        )

        # Remove read-only if file exists
        if os.path.exists(out_path):
            try:
                os.chmod(out_path, stat.S_IWRITE | stat.S_IREAD)
                os.remove(out_path)
            except Exception:
                pass

        try:
            with open(out_path, 'wb') as f:
                f.write(pem)
        except PermissionError:
            # Fallback to temp dir if destination is permission locked
            temp_dir = os.environ.get('TEMP', os.environ.get('TMP', '.'))
            out_path = os.path.join(temp_dir, 'linkdesk_oracle.key')
            with open(out_path, 'wb') as f:
                f.write(pem)

        print(f"[OK] Chave convertida com sucesso para OpenSSH: {out_path}")
        return out_path
    except Exception as err:
        print(f"[!] Falha na conversao: {err}")
        return None

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: python convert_ppk.py <arquivo.ppk> [arquivo_saida.key]")
        sys.exit(1)
    ppk = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else None
    convert_ppk(ppk, out)
