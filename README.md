# Azure App Service Todo Service

A simple Node.js Todo API designed for deployment to Azure App Service.

## Features

- Create todos
- List todos
- Mark todo done
- Update and view a custom message via web interface

## Project Structure

- `index.js` - Main application code
- `main.bicep` - Radius deployment template (currently configured for local)
- `azuredeploy.bicep` - Azure infrastructure template
- `recipes/` - Radius recipes for different deployment targets (prepared but not used)

## Running Locally

1. Install dependencies:
   ```powershell
   & "C:\Program Files\nodejs\npm.cmd" install
   ```

2. Start the app:
   ```powershell
   & "C:\Program Files\nodejs\node.exe" index.js
   ```

   The app will run on:
   - **HTTPS only:** https://localhost:3443 (self-signed certificate - accept the security warning in your browser)

3. Test the app:
   - Health check: Open https://localhost:3443/healthz in your browser (accept certificate warning) or run:
     ```powershell
     Invoke-RestMethod -Uri https://localhost:3443/healthz -SkipCertificateCheck
     ```
   - Web interface: Open https://localhost:3443/ in your browser to manage todos and update the message
   - Create a todo:
     ```powershell
     Invoke-RestMethod -Uri https://localhost:3443/todos -Method Post -Body '{"title":"My first todo"}' -ContentType 'application/json' -SkipCertificateCheck
     ```
   - List todos:
     ```powershell
     Invoke-RestMethod -Uri https://localhost:3443/todos -SkipCertificateCheck
     ```
   - Mark todo done (replace ID with actual ID from create):
     ```powershell
     Invoke-RestMethod -Uri https://localhost:3443/todos/YOUR_TODO_ID/done -Method Patch -SkipCertificateCheck
     ```
   - Update message via API:
     ```powershell
     Invoke-RestMethod -Uri https://localhost:3443/message -Method Post -Body '{"message":"Your new message"}' -ContentType 'application/json' -SkipCertificateCheck
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
