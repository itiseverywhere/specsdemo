# Todo Service Spec

## 1. Purpose

This service implements a simple Todo API (create/list/complete) and must be deployed as an **Azure App Service**. It must be designed and implemented according to **ISO 27001** requirements and follow the **Azure Well-Architected Framework**.

## 2. Functional Requirements

- Users can create todos.
- Users can list todos.
- Users can mark a todo as done.
- Users can update a custom message via a web interface and view it in the health check.

## 3. Non-Functional Requirements

### 3.1 Architecture & Deployment
- Must deploy as an **Azure App Service**.
- Infrastructure must be declared in **Bicep**.
- Deployment must be automated via script (e.g., `deploy.ps1`).

### 3.2 Security & Compliance (ISO 27001)
- Enforce **HTTPS only** (no HTTP).
- Enforce **TLS 1.2+**.
- Use **Managed Identity** for access to Azure resources.
- Store secrets in **Azure Key Vault** (no secrets in code/config).
- Use **persistent storage** (e.g., Cosmos DB) instead of in-memory.

### 3.3 Azure Well-Architected
- Follow the **Reliability** pillar: health checks, retry logic, and failover.
- Follow the **Performance Efficiency** pillar: right-size app plan, enable HTTP/2.
- Follow the **Cost Optimization** pillar: choose appropriate SKU, avoid overprovisioning.

## 4. API Contract

### Endpoints
- `GET /` - serves a web interface with an input box to update the message
- `GET /todos` - list all todos
- `POST /todos` - create a todo (body: `{ "title": "..." }`)
- `PATCH /todos/{id}/done` - mark a todo done
- `POST /message` - update the custom message (body: `{ "message": "..." }`)
- `GET /healthz` - health check (returns `{ "status": "ok", "message": "..." }`)

### Data Model
- `id`: string (UUID)
- `title`: string
- `done`: boolean
- `createdAt`: ISO8601 timestamp
- `updatedAt`: ISO8601 timestamp

## 5. Deployment Notes
- Use `azuredeploy.bicep` to provision resources.
- Use `deploy.ps1` to deploy the app and configure secrets.
- Ensure the `COSMOS_CONNECTION_STRING` is injected via Key Vault.
