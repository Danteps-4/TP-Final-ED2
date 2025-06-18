
#include <ESP8266HTTPClient.h>
#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h>
#include <EEPROM.h>


#ifndef APSSID
#define APSSID "Alarma_Setup"
#define APPSK "12345678"
#define EEPROM_SIZE 96
#endif

const char* ssid = APSSID;
const char* password = APPSK;
const char* baseUrl = "http://alarma.ed2.itcorporativa.com.ar/getInstrucciones";
const char* urlGetNuevaPass = "http://alarma.ed2.itcorporativa.com.ar/getNuevaContrasenia";
const String urlSendData = "http://alarma.ed2.itcorporativa.com.ar/sendData";

// Variables para almacenar el SSID y la contraseña de la red WiFi.
String ssidGuardado = "";
String passwordGuardada = "";
String ultimoDato = "";  // Acá guardamos lo que venga del PIC
unsigned long ultimaPeticion = 0;
const unsigned long intervalo = 2000;  // cada 2 segundos

ESP8266WebServer server(80);


/* Just a little test message.  Go to http://192.168.4.1 in a web browser
*/

void handleRoot() {

  server.send(200, "text/html", formularioHTML());
}



void setup() {
  delay(1000);
  Serial.begin(9600);
  EEPROM.begin(EEPROM_SIZE);

  leerCredenciales();  // Lee SSID y Password de la EEPROM.

  if (ssidGuardado.length() > 0) {  //Si tengo el SSID intento conectarme. Sino inicio en modo AP directamente
    WiFi.begin(ssidGuardado.c_str(), passwordGuardada.c_str());
    unsigned long tiempoInicio = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - tiempoInicio < 15000) {
      delay(500);
    }
    //Si no se conecto al wifi, lo inicio en modo AP para configurarlo.
    if (WiFi.status() != WL_CONNECTED) {
      limpiarEPROM();  //Limpio la EPROM
      ESP.restart();   // Reinicio para que inicie en modo AP
    }
  } else {
    iniciarConfiguracionAP();
  }
}



void loop() {
  if (Serial.available()) {
    ultimoDato = Serial.readStringUntil('\n');  // Leer hasta salto de línea
    enviarUltimoDato(ultimoDato);
  }

  server.handleClient();


  if (WiFi.status() == WL_CONNECTED) {
    unsigned long ahora = millis();
    if (ahora - ultimaPeticion >= intervalo) {
      ultimaPeticion = ahora;
      peticionInstrucciones();  // función nueva para procesar instrucciones del backend
    }
  } else if (ssidGuardado.length() > 0) {  //Tengo un wifi para conectarme
    //Si pasaron mas de 30s desde la ultima peticion, reinicio el modulo. Algo esta mal
    unsigned long ahora = millis();
    if (ahora - ultimaPeticion >= 30000) {
      ESP.restart();
    }
  }
}

void iniciarConfiguracionAP() {
  /* You can remove the password parameter if you want the AP to be open. */
  WiFi.softAP(ssid, password);
  IPAddress myIP = WiFi.softAPIP();
  server.on("/", handleRoot);
  server.on("/guardar", guardarWifi);
  server.begin();
}



void peticionInstrucciones() {
  HTTPClient http;
  WiFiClient client;
  delay(10);
  http.begin(client, baseUrl);

  int httpCode = http.GET();
  if (httpCode > 0) {
    String payload = http.getString();
    if (payload == "3") {
      String nuevaClave = getContraseniaNueva();
      Serial.print("3");
      delay(200);
      Serial.print(nuevaClave[0]);
      delay(200);
      Serial.print(nuevaClave[1]);
      delay(200);
      Serial.print(nuevaClave[2]);
      delay(200);
      Serial.print(nuevaClave[3]);
    } else if (payload == "5") {
      //Cambiar WIFI
      limpiarEPROM();
      delay(500);
      ESP.restart();
    } else {
      Serial.print(payload);
    }
  } else {
  }
  http.end();
}

void enviarUltimoDato(String dato) {
  HTTPClient http;
  WiFiClient client;
  delay(10);
  http.begin(client, urlSendData + "?dato=" + dato);
  int httpCode = http.GET();
  http.end();
}




void guardarWifi() {
  String nuevaSSID = server.arg("ssid");
  String nuevaPass = server.arg("pass");
  if (!nuevaSSID) {
    server.send(200, "text/html", "Wifi no valido");
    return;
  }
  guardarCredenciales(nuevaSSID, nuevaPass);
  server.send(200, "text/html", "Wifi recibido con exito!");
  delay(2000);
  ESP.restart();
}


// ------------------------------------------------------------
// Guardar en EEPROM (SSID y Password)
// ------------------------------------------------------------
void guardarCredenciales(String s, String p) {
  // Borra los primeros 64 bytes de la EEPROM para asegurar limpieza.
  // Esto es importante si una credencial anterior era más larga que la nueva.
  for (int i = 0; i < 64; ++i) {
    EEPROM.write(i, 0);
  }

  // Guarda el SSID (máximo 32 caracteres)
  for (int i = 0; i < s.length() && i < 32; ++i) {
    EEPROM.write(i, s[i]);
  }
  // Guarda el Password (máximo 32 caracteres)
  for (int i = 0; i < p.length() && i < 32; ++i) {
    EEPROM.write(32 + i, p[i]);
  }
  EEPROM.commit();  // Confirma los cambios en la EEPROM.
}


void leerCredenciales() {
  char ssidBuf[33];  // +1 para el terminador nulo
  char passBuf[33];  // +1 para el terminador nulo

  // Lee el SSID
  for (int i = 0; i < 32; ++i) {
    ssidBuf[i] = EEPROM.read(i);
  }
  ssidBuf[32] = '\0';  // Asegura que sea una cadena C terminada en nulo.

  // Lee el Password
  for (int i = 0; i < 32; ++i) {
    passBuf[i] = EEPROM.read(32 + i);
  }
  passBuf[32] = '\0';  // Asegura que sea una cadena C terminada en nulo.

  ssidGuardado = String(ssidBuf);
  passwordGuardada = String(passBuf);

  // Trim the strings to remove any null characters that might have been read
  // if the stored string was shorter than 32 characters.
  ssidGuardado.trim();
  passwordGuardada.trim();
}

void limpiarEPROM() {
  for (int i = 0; i < 64; ++i) {
    EEPROM.write(i, 0);
  }
  EEPROM.commit();
}



String formularioHTML() {
  return "<!DOCTYPE html>"
         "<html>"
         "<head>"
         "<meta charset='UTF-8'>"
         "<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
         "<title>Configurar WiFi ESP</title>"
         "<style>"
         "body { font-family: Arial, sans-serif; background-color: #f0f0f0; margin: 0; padding: 20px; display: flex; justify-content: center; align-items: center; min-height: 100vh; }"
         ".container { background-color: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); width: 100%; max-width: 400px; text-align: center; }"
         "h2 { color: #333; margin-bottom: 20px; }"
         "form { display: flex; flex-direction: column; gap: 15px; }"
         "input[type='text'], input[type='password'], input[type='submit'] { padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; width: 100%; box-sizing: border-box; }"
         ".password-container { position: relative; }"
         ".password-container input { padding-right: 40px; }"
         ".toggle-password { position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; width: 24px; height: 24px; padding: 0; }"
         ".toggle-password svg { width: 24px; height: 24px; fill: #666; }"
         "input[type='submit'] { background-color: #007bff; color: white; padding: 12px 20px; border: none; border-radius: 4px; font-size: 16px; cursor: pointer; transition: background-color 0.3s ease; }"
         "input[type='submit']:hover { background-color: #0056b3; }"
         "</style>"
         "</head>"
         "<body>"
         "<div class='container'>"
         "<h2>Configurar WiFi ESP-01</h2>"
         "<form action='/guardar' method='get'>"
         "<label for='ssid'>SSID:</label>"
         "<input type='text' id='ssid' name='ssid' required>"
         "<label for='pass'>Password:</label>"
         "<div class='password-container'>"
         "<input type='password' id='pass' name='pass'>"
         "<button type='button' class='toggle-password' onclick='togglePassword()'>"
         "<svg id='eye-icon' viewBox='0 0 24 24'>"
         "<path d='M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5C21.27 7.61 17 4.5 12 4.5zm0 12c-2.49 0-4.5-2.01-4.5-4.5S9.51 7.5 12 7.5s4.5 2.01 4.5 4.5-2.01 4.5-4.5 4.5zm0-7.5a3 3 0 100 6 3 3 0 000-6z'/>"
         "</svg>"
         "</button>"
         "</div>"
         "<input type='submit' value='Guardar'>"
         "</form>"
         "</div>"
         "<script>"
         "function togglePassword() {"
         "  var passInput = document.getElementById('pass');"
         "  var eyeIcon = document.getElementById('eye-icon');"
         "  if (passInput.type === 'password') {"
         "    passInput.type = 'text';"
         "    eyeIcon.innerHTML = \"<path d='M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5 2.06 0 3.97-.52 5.64-1.45l2.11 2.11 1.41-1.41L3.51 3.51 2.1 4.92l3.11 3.11A10.96 10.96 0 001 12c1.73 4.39 6 7.5 11 7.5 2.27 0 4.39-.66 6.15-1.78l1.93 1.93 1.41-1.41L4.92 2.1 3.51 3.51l2.45 2.45C4.27 7.4 2.73 9.59 2.73 12c0 .57.05 1.13.15 1.67l1.57 1.57C4.05 14.38 4 13.7 4 13c0-4.97 4.03-9 9-9 1.16 0 2.26.21 3.26.59l2.48 2.48c-1.04-.59-2.2-.92-3.48-.92z'/>\";"
         "  } else {"
         "    passInput.type = 'password';"
         "    eyeIcon.innerHTML = \"<path d='M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5C21.27 7.61 17 4.5 12 4.5zm0 12c-2.49 0-4.5-2.01-4.5-4.5S9.51 7.5 12 7.5s4.5 2.01 4.5 4.5-2.01 4.5-4.5 4.5zm0-7.5a3 3 0 100 6 3 3 0 000-6z'/>\";"
         "  }"
         "}"
         "</script>"
         "</body>"
         "</html>";
}


String getContraseniaNueva() {
  HTTPClient http;
  WiFiClient client;
  delay(10);
  http.begin(client, urlGetNuevaPass);
  int httpCode = http.GET();
  if (httpCode > 0) {
    String payload = http.getString();
    return payload;
  }
  return "0000";
}
