# Recipes

This folder contains Radius recipes for deploying the application to different environments.

## appservice

Deploys the container to Azure App Service with a Linux App Service Plan.

**Note:** This recipe is prepared but not currently used. To use it, update `main.bicep` to reference `recipe: { name: 'appservice' }` instead of `'default'`.

For production deployment, ensure the Azure environment is configured with the correct subscription and resource group.