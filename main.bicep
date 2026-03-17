resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'copilot'
  properties: {
    application: {
      name: 'copilot'
    }
  }
}

resource container 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'web'
  properties: {
    application: app.name
    container: {
      image: 'azure-app-service-demo:latest'
      ports: {
        http: {
          containerPort: 3000
        }
      }
    }
    recipe: {
      name: 'default'
    }
  }
}
