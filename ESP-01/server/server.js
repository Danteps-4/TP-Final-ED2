const express = require('express');
const http = require('http');
const session = require('express-session');

const app = express();
const port = 8001;
let proximaInstruccion = null;
let nuevaClave = null;
let estadoAlarma = "Desactivada";
let ultimaActualizacion = new Date().getTime()
const server = http.createServer(app);

// Variable para el estado de la alarma (temporal)

// Configuración de sesión
app.use(session({
  secret: 'tu_secreto_seguro',
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false } // En producción debería ser true si usas HTTPS
}));

// Middleware para verificar autenticación
const requireAuth = (req, res, next) => {
  if (req.session.authenticated) {
    next();
  } else {
    res.redirect('/login');
  }
};

// Ruta de login
app.get('/login', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Login - Control Alarma</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: 'Segoe UI', sans-serif;
      background: linear-gradient(135deg, #2c3e50, #3498db);
      height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .container {
      background-color: #ffffff;
      padding: 30px 40px;
      border-radius: 12px;
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
      text-align: center;
      max-width: 350px;
      width: 90%;
      animation: fadeIn 1s ease-out;
    }

    h2 {
      color: #2c3e50;
      margin-bottom: 20px;
    }

    .button {
      display: block;
      width: 100%;
      padding: 12px;
      margin: 10px 0;
      font-size: 16px;
      font-weight: bold;
      border: none;
      border-radius: 6px;
      background-color: #3498db;
      color: white;
      cursor: pointer;
      transition: background-color 0.3s, transform 0.2s;
    }

    .button:hover {
      background-color: #2980b9;
      transform: translateY(-2px);
    }

    .button:active {
      transform: scale(0.98);
    }

    input[type="text"], input[type="password"] {
      padding: 10px;
      width: 100%;
      margin: 10px 0;
      font-size: 16px;
      border: 1px solid #ccc;
      border-radius: 6px;
      box-sizing: border-box;
    }

    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(20px); }
      to { opacity: 1; transform: translateY(0); }
    }
  </style>
</head>
<body>
  <div class="container">
    <h2>Login - Control Alarma</h2>
    <form id="loginForm" onsubmit="return false;">
      <input type="text" id="usuario" placeholder="Usuario" required>
      <input type="password" id="password" placeholder="Contraseña" required>
      <button class="button" onclick="login()">Ingresar</button>
    </form>
  </div>

  <script>
    function login() {
      const usuario = document.getElementById('usuario').value;
      const password = document.getElementById('password').value;

      fetch('/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ usuario, password })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          window.location.href = '/';
        } else {
          alert('Usuario o contraseña incorrectos');
        }
      });
    }
  </script>
</body>
</html>
  `);
});

// Endpoint para procesar el login
app.post('/login', express.json(), (req, res) => {
  const { usuario, password } = req.body;
  if (usuario?.toUpperCase() === 'ED2' && password === '2025') {
    req.session.authenticated = true;
    res.json({ success: true });
  } else {
    res.json({ success: false });
  }
});

app.get('/getInstrucciones', (req, res) => {
  console.log('Enviando instruccion: ' + proximaInstruccion);
  let cod = null;
  switch (proximaInstruccion) {
    case "activarAlarma":
      cod = "1";
      break;
    case "desactivarAlarma":
      cod = "2";
      break;
    case "cambiarContrasenia":
      cod = "3";
      break;
    case "cambiarWifi":
      cod = "5";
      break;
  }
  res.send(cod);
  console.log("Envio un " + cod);
  proximaInstruccion = null;
});

app.get('/sendData', (req, res) => {
  ultimaActualizacion = new Date().getTime();
  console.log("Dato recibido: " + req.query.dato);
  if (req.query.dato.includes("A")) {
    //ALARMA ACTIVADA
    estadoAlarma = "Activada";
  } else if (req.query.dato.includes("B")) {
    //ALARMA DESACTIVADA
    estadoAlarma = "Desactivada";
  } else if (req.query.dato.includes("C")) {
    // ACTIVANDO ALARMA
    estadoAlarma = "Activando alarma";
  }
});

app.get('/getNuevaContrasenia', (req, res) => {
  console.log("Envio nueva clave: " + nuevaClave);
  if (nuevaClave) {
    res.send(nuevaClave.toString());
    nuevaClave = null;
  } else {
    res.send("0000")
  }
});



// Proteger todas las rutas de abajo
app.use(requireAuth);



app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Control Alarma</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: 'Segoe UI', sans-serif;
      background: linear-gradient(135deg, #2c3e50, #3498db);
      height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .container {
      background-color: #ffffff;
      padding: 30px 40px;
      border-radius: 12px;
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
      text-align: center;
      max-width: 700px;
      width: 90%;
      animation: fadeIn 1s ease-out;
    }

    h2 {
      color: #2c3e50;
      margin-bottom: 20px;
    }

    .button {
      display: inline-block;
      min-width: 120px;
      padding: 12px;
      margin: 10px 5px;
      font-size: 16px;
      font-weight: bold;
      border: none;
      border-radius: 6px;
      background-color: #3498db;
      color: white;
      cursor: pointer;
      transition: background-color 0.3s, transform 0.2s;
    }

    .button:hover {
      background-color: #2980b9;
      transform: translateY(-2px);
    }

    .button:active {
      transform: scale(0.98);
    }

    .warning {
      background-color: #f39c12 !important;
    }

    #formClave {
      display: none;
      margin-top: 10px;
    }

    input[type="text"] {
      padding: 10px;
      width: 200px;
      margin-top: 10px;
      font-size: 16px;
      border: 1px solid #ccc;
      border-radius: 6px;
      box-sizing: border-box;
    }

    .estado-container {
      margin-bottom: 20px;
      padding: 15px;
      border-radius: 8px;
      background-color: #f8f9fa;
      position: relative;
      overflow: hidden;
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    }

    .estado-titulo {
      font-size: 14px;
      color: #666;
      margin-bottom: 5px;
      text-align: left;
    }

    .estado-valor {
      font-size: 18px;
      font-weight: bold;
      display: flex;
      align-items: center;
      justify-content: flex-end;
      gap: 10px;
    }

    .estado-activada {
      color: #e74c3c;
    }

    .estado-desactivada {
      color: #27ae60;
    }

    .estado-activandoalarma {
      color: #f39c12;
    }

    .estado-sinconexion {
      color: #000000;
    }

    .estado-indicador {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      display: inline-block;
    }

    .estado-activada .estado-indicador {
      background-color: #e74c3c;
      box-shadow: 0 0 10px #e74c3c;
    }

    .estado-desactivada .estado-indicador {
      background-color: #27ae60;
      box-shadow: 0 0 10px #27ae60;
    }

    .estado-activandoalarma .estado-indicador {
      background-color: #f39c12;
      box-shadow: 0 0 10px #f39c12;
      animation: pulse 1.5s infinite;
    }

    .estado-sinconexion .estado-indicador {
      background-color: #000000;
      box-shadow: 0 0 10px #000000;
    }

    @keyframes pulse {
      0% {
        transform: scale(1);
        opacity: 1;
      }
      50% {
        transform: scale(1.2);
        opacity: 0.7;
      }
      100% {
        transform: scale(1);
        opacity: 1;
      }
    }

    .loading-spinner {
      width: 20px;
      height: 20px;
      border: 3px solid #f3f3f3;
      border-top: 3px solid #f39c12;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      display: none;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    .estado-activandoalarma .loading-spinner {
      display: none;
    }

    @media (max-width: 480px) {
      .button {
        font-size: 15px;
        padding: 10px;
        min-width: 90px;
      }
      .container {
        padding: 10px 2px;
        max-width: 98vw;
      }
      .estado-valor {
        font-size: 15px;
      }
    }

    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(20px); }
      to { opacity: 1; transform: translateY(0); }
    }
  </style>
</head>
<body>
  <div class="container">
    <h2>Control Alarma</h2>

    <div class="estado-container">
      <div class="estado-titulo">Estado actual</div>
      <div id="estadoAlarma" class="estado-valor" style="width: 100%; justify-content: center;">
        <span class="estado-indicador"></span>
        <span id="estadoTexto">Cargando...</span>
        <div class="loading-spinner"></div>
      </div>
    </div>

    <div id="botones">
      <button class="button" onclick="enviar('activarAlarma')">Activar</button>
      <button class="button" onclick="enviar('desactivarAlarma')">Desactivar</button>
      <button class="button" onclick="mostrarForm()">Cambiar contraseña</button>
      <button class="button" onclick="enviar('cambiarWifi')">Olvidar WiFi</button>
      <button class="button warning" onclick="logout()">Cerrar Sesión</button>
    </div>

    <div id="formClave">
      <input type="text" id="nuevaClave" placeholder="Nueva clave (4 dígitos)" maxlength="4">
      <button class="button warning" onclick="enviarClave()">Enviar nueva contraseña</button>
    </div>
  </div>

  <script>
    function enviar(cmd) {
      fetch('/enviar?cmd=' + cmd);
    }

    function mostrarForm() {
      document.getElementById('formClave').style.display = 'block';
      document.getElementById('botones').style.display = 'none';
    }

    function enviarClave() {
      const clave = document.getElementById('nuevaClave').value;
      const numero = parseInt(clave);

      if (!isNaN(numero) && clave.length === 4 && /^[0-9]+$/.test(clave)) {
        fetch('/enviar?cmd=cambiarContrasenia&clave=' + clave);
        alert("Nueva contraseña enviada.");
        document.getElementById('formClave').style.display = 'none';
        document.getElementById('botones').style.display = 'block';
      } else {
        alert("La clave debe tener exactamente 4 dígitos numéricos.");
      }
    }

    function logout() {
      fetch('/logout').then(() => {
        window.location.href = '/login';
      });
    }

    function actualizarEstado() {
      fetch('/estadoAlarma')
        .then(response => response.json())
        .then(data => {
          const estadoElement = document.getElementById('estadoAlarma');
          const estadoTexto = document.getElementById('estadoTexto');
          
          // Remover clases anteriores
          estadoElement.classList.remove('estado-activada', 'estado-desactivada', 'estado-activandoalarma', 'estado-sinconexion');
          
          // Actualizar estado
          estadoTexto.textContent = data.estado;
          if (data.estado === "Activando alarma") {
            estadoElement.classList.add('estado-activandoalarma');
          } else if (data.estado === "Sin conexión") {
            estadoElement.classList.add('estado-sinconexion');
          } else {
            estadoElement.classList.add('estado-' + data.estado.toLowerCase().replace(/ /g, ''));
          }
        })
        .catch(error => {
          console.error('Error al obtener el estado:', error);
        });
    }

    // Actualizar estado cada 2 segundos
    setInterval(actualizarEstado, 1000);
    // Actualizar estado inmediatamente al cargar
    actualizarEstado();
  </script>
</body>
</html>
  `);
});




// Endpoint para obtener el estado de la alarma
app.get('/estadoAlarma', (req, res) => {
  if (new Date().getTime() - ultimaActualizacion > 15000) {
    res.json({ estado: "Sin conexión" });
  } else
    res.json({ estado: estadoAlarma });
});

app.get('/enviar', (req, res) => {
  console.log("Recibido comando: " + req.query.cmd);
  proximaInstruccion = req.query.cmd;
  res.send("Comando recibido: " + proximaInstruccion);
  if (proximaInstruccion == "cambiarContrasenia") {
    nuevaClave = req.query.clave;
  }
});

app.get('/alarmaDesactivada', (req, res) => {
  console.log("Alarma desactivada");
  res.send(true);
});

// Ruta para cerrar sesión
app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Servidor corriendo en http://192.168.1.173:${port}`);
});
