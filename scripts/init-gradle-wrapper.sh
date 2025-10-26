#!/bin/bash
set -e

echo "Downloading Gradle wrapper jar..."

mkdir -p gradle/wrapper

# Download gradle-wrapper.jar
curl -L -o gradle/wrapper/gradle-wrapper.jar \
  https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar

echo "Gradle wrapper jar downloaded successfully!"
echo "You can now run: ./gradlew build"
