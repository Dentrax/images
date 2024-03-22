#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

CONTAINER_NAME="confluent-kafka-$(uuidgen)"
KAFKA_PORT="${FREE_PORT}"

docker run \
  -d --rm \
  --name "${CONTAINER_NAME}" \
  -h kafka-kraft \
  -p "${KAFKA_PORT}":9092 \
  -e KAFKA_NODE_ID=1 \
  -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP='CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT' \
  -e KAFKA_ADVERTISED_LISTENERS='PLAINTEXT://kafka-kraft:29092,PLAINTEXT_HOST://localhost:9092' \
  -e KAFKA_JMX_PORT=9101 \
  -e KAFKA_JMX_HOSTNAME=localhost \
  -e KAFKA_PROCESS_ROLES='broker,controller' \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  -e KAFKA_CONTROLLER_QUORUM_VOTERS='1@kafka-kraft:29093' \
  -e KAFKA_LISTENERS='PLAINTEXT://kafka-kraft:29092,CONTROLLER://kafka-kraft:29093,PLAINTEXT_HOST://0.0.0.0:9092' \
  -e KAFKA_INTER_BROKER_LISTENER_NAME='PLAINTEXT' \
  -e KAFKA_CONTROLLER_LISTENER_NAMES='CONTROLLER' \
  -e CLUSTER_ID='MkU3OEVBNTcwNTJENDM2Qk' \
  "${IMAGE_NAME}"

sleep 10

logs=$(docker logs "${CONTAINER_NAME}" 2>&1)

trap "docker stop ${CONTAINER_NAME}" EXIT

function dump_logs_and_exit {
  echo "Dumping logs and exiting..."
  echo "Docker logs:"
  docker logs "${CONTAINER_NAME}"
  echo "Kafka logs:"
  docker exec "${CONTAINER_NAME}" cat /usr/lib/kafka/logs/kafka.err || true
  docker exec "${CONTAINER_NAME}" cat /usr/lib/kafka/logs/kafka.out || true
  docker exec "${CONTAINER_NAME}" cat /usr/lib/kafka/logs/controller.log || true
  exit 1
}

function assert_kafka {
  echo "Checking Kafka status..."
  nc -zv localhost "${KAFKA_PORT}" || { echo "Kafka is not listening on port ${KAFKA_PORT}:9092"; dump_logs_and_exit; }
  docker exec "${CONTAINER_NAME}" cat /usr/lib/kafka/logs/controller.log | grep "Controller 0 connected" || { echo "Kafka log entry not found"; dump_logs_and_exit; }
  echo "Kafka is up and running!"
}

function assert_kafka_kraft {
  echo "Checking Kafka Kraft status..."
  echo "${logs}" | grep "Kafka Server started (kafka.server.KafkaRaftServer)" || { echo "Kafka Kraft is not up and running"; dump_logs_and_exit; }
  echo "Kafka Kraft is up and running!"
}

function test_produce_consume {
  TOPIC_NAME="test-topic-$(uuidgen)"
  PARTITIONS=1
  REPLICATION_FACTOR=1

  # Create a Kafka topic
  docker exec "${CONTAINER_NAME}" kafka-topics --create --topic "${TOPIC_NAME}" --partitions "${PARTITIONS}" --replication-factor "${REPLICATION_FACTOR}" --if-not-exists --bootstrap-server localhost:"${KAFKA_PORT}"

  # Produce a test message
  echo "Hello Kafka" | docker exec -i "${CONTAINER_NAME}" kafka-console-producer --broker-list localhost:"${KAFKA_PORT}" --topic "${TOPIC_NAME}"

  # Consume the message
  consumed_message=$(docker exec "${CONTAINER_NAME}" timeout 10 kafka-console-consumer --bootstrap-server localhost:"${KAFKA_PORT}" --topic "${TOPIC_NAME}" --from-beginning --max-messages 1)

  # Verify the message
  if [[ "${consumed_message}" == "Hello Kafka" ]]; then
    echo "Successfully produced and consumed a test message."
  else
    echo "Failed to verify the consumed message."
    dump_logs_and_exit
  fi

  # Clean up the test topic (optional)
  docker exec "${CONTAINER_NAME}" kafka-topics --delete --topic "${TOPIC_NAME}" --bootstrap-server localhost:"${KAFKA_PORT}"
}

assert_kafka
assert_kafka_kraft

# Perform the produce-consume test
test_produce_consume

echo "All tests passed!"
