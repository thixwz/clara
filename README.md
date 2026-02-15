# CLARA - Clinical Language And Report Analyzer

CLARA is a full-stack application designed to analyze and explain medical diagnosis reports using local Large Language Models (LLMs) and Retrieval-Augmented Generation (RAG).

The system is architected to prioritize data privacy and accessibility by running inference locally or within isolated containerized environments, minimizing reliance on external cloud AI providers for sensitive data processing.

## Project Overview

The primary goal of this project is to bridge the information gap between complex medical terminology and patient understanding. It employs Optical Character Recognition (OCR) to digitize physical reports and uses a vector search mechanism to ground AI responses in the specific context of the uploaded document.

### Core Features

*   **Offline Inference:** Utilizes quantized GGUF models (e.g., MedAlpaca, Mistral) to run on consumer hardware with limited RAM.
*   **RAG Architecture:** Implements a retrieval pipeline using FAISS and LangChain to prevent hallucinations by referencing the source document.
*   **Cross-Platform Client:** A Flutter-based mobile application for iOS and Android.
*   **Containerized Backend:** A Python FastAPI service fully containerized with Docker for consistent deployment across local and cloud environments (AWS).

## System Architecture

The project follows a microservices pattern separating the client-side logic from the inference engine.

### Directory Structure

*   `backend/`: Contains the Python FastAPI server, RAG logic, and Docker configuration.
*   `mobile/`: Contains the Flutter source code for the mobile client.

### Technology Stack

*   **Mobile:** Flutter, Dart, Hive (Local Storage)
*   **Backend:** Python 3.9, FastAPI, Uvicorn
*   **AI/ML:** LangChain, Llama.cpp, FAISS, PyMuPDF
*   **Database:** MongoDB Atlas (Session Management)
*   **Infrastructure:** Docker, AWS (EC2 compatible)

## Installation and Execution

### Prerequisites

*   Docker Desktop
*   Python 3.9+
*   Approximately 4GB RAM available for model inference.

### 1. Backend Setup (Docker)

The backend is configured to run inside a Docker container. To avoid bloating the container image, the heavy model weights (`.gguf` files) are mounted via Docker Volumes.

Build the image:

```bash
cd backend
docker build -t clara-backend .
2. Mobile Client Setup
Ensure you have the Flutter SDK installed.

Bash

cd mobile
flutter pub get
flutter run
Technical Implementation Details
Optimization
To address memory constraints on standard instances, the system uses 4-bit quantization for the LLM. This reduces the VRAM/RAM requirement by approximately 70% compared to full-precision models, allowing deployment on standard CPU instances or AWS Spot Instances.

CI/CD and Version Control
The project utilizes Git for version control, with a clear separation between the backend service and mobile frontend to facilitate independent development cycles.