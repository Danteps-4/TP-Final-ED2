
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
const char* baseUrl = "http://192.168.1.173:8001/getInstrucciones";
const char* urlGetNuevaPass = "http://192.168.1.173:8001/getNuevaContrasenia";
const char* urlSendData = "http://192.168.1.173:8001/sendData";

// Variables para almacenar el SSID y la contraseña de la red WiFi.
String ssidGuardado = "";
String passwordGuardada = "";


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


  WiFi.begin(ssidGuardado.c_str(), passwordGuardada.c_str());

  unsigned long tiempoInicio = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - tiempoInicio < 15000) {
    delay(500);
  }

  if (WiFi.status() == WL_CONNECTED) {

    while (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;
      WiFiClient client;
      delay(500);
      http.begin(client, baseUrl);

      int httpCode = http.GET();
      if (httpCode > 0) {
        String payload = http.getString();
        if (payload == "activarAlarma") {
          Serial.print("1");
        } else if (payload == "desactivarAlarma") {
          Serial.print("2");
        } else if (payload == "cambiarWifi") {
          limpiarEPROM();
          ESP.restart();
        } else if (payload == "reiniciarESP") {
          ESP.restart();
        } else if (payload == "cambiarContrasenia") {
          String nuevaClave = getContraseniaNueva();
          Serial.print("3");
          delay(500);
          Serial.print(nuevaClave);
        } else {
        }
      } else {
      }
      http.end();
      delay(2000);
    }
    ESP.restart();
  } else {
    iniciarConfiguracionAP();
  }
}



void loop() {

  if (Serial.available()) {
    char c = Serial.read();
    Serial.print("Recibido: ");
    Serial.println(c);
  }
  server.handleClient();
}

void iniciarConfiguracionAP() {
  /* You can remove the password parameter if you want the AP to be open. */
  WiFi.softAP(ssid, password);
  IPAddress myIP = WiFi.softAPIP();
  server.on("/", handleRoot);
  server.on("/guardar", guardarWifi);
  server.begin();
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
         "input[type='text'], input[type='password'] { padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; }"
         ".password-container { position: relative; }"
         ".toggle-password { position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; font-size: 16px; }"
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
         "<button type='button' class='toggle-password' onclick='togglePassword()'>👁️</button>"
         "</div>"
         "<input type='submit' value='Guardar'>"
         "</form>"
         "</div>"
         "<script>"
         "function togglePassword() {"
         "  var passInput = document.getElementById('pass');"
         "  if (passInput.type === 'password') {"
         "    passInput.type = 'text';"
         "  } else {"
         "    passInput.type = 'password';"
         "  }"
         "}"
         "</script>"
         "</body>"
         "</html>";
}


String getContraseniaNueva() {
  HTTPClient http;
  WiFiClient client;
  delay(500);
  http.begin(client, urlGetNuevaPass);
  int httpCode = http.GET();
  if (httpCode > 0) {
    String payload = http.getString();
    return payload;
  }
  return "0000";
}