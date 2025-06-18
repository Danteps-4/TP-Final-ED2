const { SerialPort } = require('serialport');

// Cambia el puerto según tu sistema
const port = new SerialPort({
  path: 'COM4', // ej. COM3 en Windows o /dev/ttyUSB0 en Linux
  baudRate: 115200 // Debe coincidir con el del PIC
});

// Leer datos del PIC
port.on('data', (data) => {
  console.log(data.toString());
});

// Función para enviar datos al PIC
function enviarDato(dato) {
  port.write(dato, (err) => {
    if (err) {
      console.error('Error al enviar datos:', err);
    } else {
      console.log('Dato enviado correctamente');
    }
  });
}
//enviarDato('5')

// Ejemplo de uso:
// enviarDato('H'); // Enviar un carácter
// enviarDato('Hola'); // Enviar una cadena
// enviarDato(Buffer.from([0x41])); // Enviar un byte (0x41 = 'A')


