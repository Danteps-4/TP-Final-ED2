#include <EEPROM.h>

#define EEPROM_SIZE 512  // Tamaño típico del ESP-01

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("Borrando EEPROM...");

  EEPROM.begin(EEPROM_SIZE);

  for (int i = 0; i < EEPROM_SIZE; i++) {
    EEPROM.write(i, 0);  // Escribe 0 en cada posición
  }

  EEPROM.commit();  // Guarda los cambios en la memoria flash

  Serial.println("EEPROM borrada correctamente.");
}

void loop() {
  // Nada
}
