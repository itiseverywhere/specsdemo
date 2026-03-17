# Azure App Service Todo Service

A simple Node.js Todo API designed for deployment to Azure App Service.

## Features

- Create todos
- List todos
- Mark todo done
- Update and view a custom message via web interface

## Running Locally

1. Install dependencies:
   ```powershell
   & "C:\Program Files\nodejs\npm.cmd" install
   ```

2. Start the app:
   ```powershell
   & "C:\Program Files\nodejs\node.exe" index.js
   ```

3. Test the app:
   - Health check: Open http://localhost:3000/healthz in your browser or run:
     ```powershell
     Invoke-RestMethod -Uri http://localhost:3000/healthz
     ```
   - Web interface: Open http://localhost:3000/ in your browser to update the message
   - Update message via API:
     ```powershell
     Invoke-RestMethod -Uri http://localhost:3000/message -Method Post -Body '{"message":"Your new message"}' -ContentType 'application/json'
     ```
   - Create a todo:
     ```powershell
     Invoke-RestMethod -Uri http://localhost:3000/todos -Method Post -Body '{"title":"My first todo"}' -ContentType 'application/json'
     ```
   - List todos:
     ```powershell
     Invoke-RestMethod -Uri http://localhost:3000/todos
     ```
   - Mark todo done (replace ID with actual ID from create):
     ```powershell
     Invoke-RestMethod -Uri http://localhost:3000/todos/YOUR_TODO_ID/done -Method Patch
     ```

3. Open http://localhost:3000

## API Endpoints

- `GET /todos` - List all todos
- `POST /todos` - Create a todo (body: `{ "title": "..." }`)
- `PATCH /todos/{id}/done` - Mark a todo as done
- `GET /healthz` - Health check endpoint

## Deploying to Azure App Service

This repo includes a Bicep template (`azuredeploy.bicep`) and a deployment script (`deploy.ps1`).

1. Sign in to Azure:
   ```powershell
   az login
   ```

2. Run the deploy script (adjust resource group or name if desired):
   ```powershell
   .\deploy.ps1 -ResourceGroupName todo-rg -Location eastus -WebAppName todo-app-service
   ```

3. The script will output the app URL once deployment completes.

## Security & Best Practices (ISO 27001 / Azure Well-Architected)

- HTTPS-only enforced (`httpsOnly: true`)
- TLS 1.2 minimum
- System-assigned managed identity enabled
- Clean separation of infrastructure (Bicep) and application code
- Health check endpoint for monitoring

For production usage, add a persistent datastore (Cosmos DB, Azure SQL, etc.) and secure credentials using Azure Key Vault.
