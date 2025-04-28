import pika
import sys
import time
import socket

def test_rabbitmq_connection():
    try:
        # First, let's check if we can resolve the hostname
        print(f"Attempting to resolve 'localhost'...")
        try:
            ip = socket.gethostbyname('localhost')
            print(f"Successfully resolved 'localhost' to IP: {ip}")
        except socket.gaierror as e:
            print(f"Failed to resolve 'localhost': {str(e)}")
            return False

        # Try different connection parameters
        credentials = pika.PlainCredentials('opencti', 'admin@123')
        
        # Try with different connection parameters
        connection_params = [
            pika.ConnectionParameters(
                host='localhost',
                port=5672,
                credentials=credentials,
                heartbeat=60
            ),
            pika.ConnectionParameters(
                host='127.0.0.1',
                port=5672,
                credentials=credentials,
                heartbeat=60
            ),
            pika.ConnectionParameters(
                host='172.18.0.2',  # Docker network IP
                port=5672,
                credentials=credentials,
                heartbeat=60
            )
        ]

        for params in connection_params:
            print(f"\nTrying connection with host: {params.host}")
            try:
                print("Attempting to connect to RabbitMQ...")
                connection = pika.BlockingConnection(params)
                print(f"Successfully connected to RabbitMQ at {params.host}!")

                # Create a channel
                channel = connection.channel()
                print("Channel created successfully")

                # Declare a queue
                queue_name = 'test_queue'
                channel.queue_declare(queue=queue_name)
                print(f"Queue '{queue_name}' declared successfully")

                # Publish a test message
                message = "Test message from Python script"
                channel.basic_publish(exchange='', routing_key=queue_name, body=message)
                print(f"Published message: {message}")

                # Close the connection
                connection.close()
                print("Connection closed successfully")
                return True

            except pika.exceptions.AMQPConnectionError as e:
                print(f"Connection failed: {str(e)}")
            except Exception as e:
                print(f"Unexpected error: {str(e)}")
                print(f"Error type: {type(e).__name__}")
                import traceback
                print("Full traceback:")
                print(traceback.format_exc())

        return False

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        import traceback
        print("Full traceback:")
        print(traceback.format_exc())
        return False

if __name__ == "__main__":
    print("Starting RabbitMQ connection test...")
    success = test_rabbitmq_connection()
    if success:
        print("Test completed successfully!")
    else:
        print("Test failed!")
        sys.exit(1) 