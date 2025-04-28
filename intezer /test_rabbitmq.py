import pika
import sys
import time

def test_rabbitmq_connection():
    try:
        # Connection parameters
        credentials = pika.PlainCredentials('guest', 'guest')
        parameters = pika.ConnectionParameters(
            host='localhost',
            port=5672,
            credentials=credentials,
            heartbeat=60
        )

        print("Attempting to connect to RabbitMQ...")
        connection = pika.BlockingConnection(parameters)
        print("Successfully connected to RabbitMQ!")

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

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        return False

if __name__ == "__main__":
    print("Starting RabbitMQ connection test...")
    success = test_rabbitmq_connection()
    if success:
        print("Test completed successfully!")
    else:
        print("Test failed!")
        sys.exit(1) 