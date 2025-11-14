import amqp from "amqplib";
import dotenv from "dotenv";

dotenv.config({ path: './config/.env' });

async function sendProduct(product) {
  const queue = process.env.RABBIT_QUEUE;

  try {
    const connectionString = `${process.env.RABBIT_PROTOCOL}://${process.env.RABBIT_USER}:${process.env.RABBIT_PASS}@${process.env.RABBIT_HOST}:${process.env.RABBIT_PORT}`;
    
    const connection = await amqp.connect(connectionString);
    const channel = await connection.createChannel();

    // Persistent Queue
    await channel.assertQueue(queue, { durable: true });

    const message = JSON.stringify(product);

    channel.sendToQueue(queue, Buffer.from(message), {
      persistent: true, // Storage message on the disc
    });

    console.log("Message sent:", message);

    await channel.close();
    await connection.close();
  } catch (error) {
    console.error("Erro ao enviar mensagem:", error);
  }
}

// Product Example
sendProduct({
  id: 123,
  product: "T-Shirt",
  value: 59.90,
  stock: 2,
});