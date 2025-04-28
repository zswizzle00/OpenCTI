import socket
import sys

def check_port(host, port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)  # 5 second timeout
    
    try:
        print(f"Attempting to connect to {host}:{port}...")
        result = sock.connect_ex((host, port))
        if result == 0:
            print(f"Port {port} is OPEN and accessible on {host}")
            return True
        else:
            print(f"Port {port} is CLOSED or not accessible on {host}")
            return False
    except socket.gaierror:
        print(f"Hostname {host} could not be resolved")
        return False
    except socket.error as e:
        print(f"Error connecting to {host}:{port} - {str(e)}")
        return False
    finally:
        sock.close()

if __name__ == "__main__":
    hosts = ['localhost', '127.0.0.1', '172.18.0.2']
    port = 5672
    
    print("Checking RabbitMQ port accessibility...")
    for host in hosts:
        print(f"\nTesting {host}:")
        check_port(host, port) 