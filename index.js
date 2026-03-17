const express = require('express');
const { randomUUID } = require('crypto');

const { CosmosClient } = require('@azure/cosmos');

const app = express();
app.use(express.json());

const port = process.env.PORT || 3000;

// Use Cosmos DB if configured (suitable for production, persistent storage)
const cosmosConnectionString = process.env.COSMOS_CONNECTION_STRING;
let todos = new Map();
let cosmosContainer;
let currentMessage = 'hello world';

async function initCosmos() {
  if (!cosmosConnectionString) {
    return;
  }

  const client = new CosmosClient(cosmosConnectionString);
  const database = client.database('todos-db');
  cosmosContainer = database.container('todos');

  // Ensure container exists (idempotent)
  await database.containers.createIfNotExists({ id: 'todos', partitionKey: { paths: ['/id'] } });

  // Load existing items into memory for fast reads (optional)
  const { resources } = await cosmosContainer.items.readAll().fetchAll();
  todos = new Map(resources.map((item) => [item.id, item]));
}

function toDto(todo) {
  return {
    id: todo.id,
    title: todo.title,
    done: todo.done,
    createdAt: todo.createdAt,
    updatedAt: todo.updatedAt,
  };
}

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Todo App</title>
    </head>
    <body>
      <h1>Todo App</h1>
      
      <h2>Update the Message</h2>
      <input id="msg" type="text" value="${currentMessage.replace(/"/g, '&quot;')}" style="width: 300px;">
      <button onclick="updateMessage()">Update Message</button>
      <p>Current message: <span id="current">${currentMessage}</span></p>
      
      <h2>Todos</h2>
      <input id="todoTitle" type="text" placeholder="New todo title" style="width: 300px;">
      <button onclick="createTodo()">Create Todo</button>
      <ul id="todoList"></ul>
      
      <script>
        async function updateMessage() {
          const message = document.getElementById('msg').value;
          const response = await fetch('/message', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message })
          });
          if (response.ok) {
            document.getElementById('current').textContent = message;
          }
        }
        
        async function loadTodos() {
          const response = await fetch('/todos');
          const todos = await response.json();
          const list = document.getElementById('todoList');
          list.innerHTML = '';
          todos.forEach(todo => {
            const li = document.createElement('li');
            li.textContent = todo.title + (todo.done ? ' (done)' : '');
            if (!todo.done) {
              const button = document.createElement('button');
              button.textContent = 'Mark Done';
              button.onclick = () => markDone(todo.id);
              li.appendChild(button);
            }
            list.appendChild(li);
          });
        }
        
        async function createTodo() {
          const title = document.getElementById('todoTitle').value;
          if (!title) return;
          const response = await fetch('/todos', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title })
          });
          if (response.ok) {
            document.getElementById('todoTitle').value = '';
            loadTodos();
          }
        }
        
        async function markDone(id) {
          const response = await fetch('/todos/' + id + '/done', { method: 'PATCH' });
          if (response.ok) {
            loadTodos();
          }
        }
        
        loadTodos();
      </script>
    </body>
    </html>
  `);
});

app.get('/healthz', (req, res) => {
  res.send({ status: 'ok', message: currentMessage });
});

app.post('/message', (req, res) => {
  const { message } = req.body;
  if (typeof message !== 'string') {
    return res.status(400).send({ error: 'message must be a string' });
  }
  currentMessage = message;
  res.send({ status: 'ok' });
});

app.get('/todos', (req, res) => {
  res.send(Array.from(todos.values()).map(toDto));
});

app.post('/todos', async (req, res) => {
  const { title } = req.body;
  if (!title || typeof title !== 'string') {
    return res.status(400).send({ error: 'title is required' });
  }

  const todo = {
    id: randomUUID(),
    title: title.trim(),
    done: false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  todos.set(todo.id, todo);

  if (cosmosContainer) {
    await cosmosContainer.items.create(todo);
  }

  res.status(201).send(toDto(todo));
});

app.patch('/todos/:id/done', async (req, res) => {
  const { id } = req.params;
  const todo = todos.get(id);
  if (!todo) {
    return res.status(404).send({ error: 'todo not found' });
  }

  todo.done = true;
  todo.updatedAt = new Date().toISOString();
  todos.set(id, todo);

  if (cosmosContainer) {
    await cosmosContainer.item(id, id).replace(todo);
  }

  res.send(toDto(todo));
});

async function start() {
  if (cosmosConnectionString) {
    try {
      await initCosmos();
      console.log('Using Cosmos DB for persistence.');
    } catch (err) {
      console.error('Failed to initialize Cosmos DB, falling back to in-memory store.', err);
    }
  } else {
    console.log('No COSMOS_CONNECTION_STRING defined; using in-memory store.');
  }

  app.listen(port, () => {
    console.log(`App listening on port ${port}`);
  });
}

start();