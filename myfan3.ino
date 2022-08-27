#include <TroykaDHT.h>
#define DHTPIN 2
DHT dht(DHTPIN, DHT11);
#define PWMPIN 3
// initial PWM
int pwmnow = 2;
const int mini = pwmnow;
int ch = 0;
int c;
const char TERM_SYMBOL = ';';
String inputString = "";
byte bl = 0;
byte bli = 1;
bool dht_connected = false;

// Format of input string
// =(+-)X;       adjsut_pwm up/down
// =X;           set_pwm
// =get_json;      get_data 

void setup() {
  pinMode(0, OUTPUT);
  pinMode(PWMPIN, OUTPUT);
  digitalWrite(PWMPIN, LOW);
  dht.begin();
  pwm25khzBegin();
  delay(100);
  pwmDuty(pwmnow);
  Serial.begin(115200);
  while (!Serial) {
    delay(100);
  }
  Serial.setTimeout(500);

// Check connected DHT11 ?
  dht.read();
  switch(dht.getState()) {
    // всё OK
    case DHT_OK:
      dht_connected = true;
      break;
  }  
}

void adjust_pwm(int pwm) {
  pwmnow += pwm;
  if (pwmnow > 99) { pwmnow = 99; }
  if (pwmnow < mini) { pwmnow = mini; }
//  Serial.print("adjust pwm ");
//  Serial.println(pwmnow);
  pwmDuty(pwmnow);
}

void set_pwm(int pwm) {
  pwmnow = pwm;
  if (pwmnow > 99) { pwmnow = 99; }
  if (pwmnow < mini) { pwmnow = mini; }
//  Serial.print("set pwm ");
//  Serial.println(pwmnow);
  pwmDuty(pwmnow);
}

void get_json() {
  int temp;
  if (dht_connected) {
    dht.read();
    temp = dht.getTemperatureC();
  }
  Serial.print("{");
  Serial.print('"');
  Serial.print("pwm");
  Serial.print('"');
  Serial.print(":[");
  Serial.print(pwmnow);
  Serial.print("],");
  Serial.print('"');
  Serial.print("temp");
  Serial.print('"');
  Serial.print(":[");
  if (dht_connected) {
      Serial.print(temp);
  }
  Serial.print("]}");
  Serial.write(0xA); // For UNIX
}

void loop() {
  if (Serial.available() > 0) {
    c = Serial.read();
    if (c == '=') {
      inputString = "";
    }
    else
    if ((char)c == TERM_SYMBOL) {
      if (inputString[0] == '+' || inputString[0] == '-') { adjust_pwm(inputString.toInt()); }
      else if ( inputString[0]-'0' >= 0 && inputString[0]-'0' <= 9 ) { set_pwm(inputString.toInt());  }
      else {
        if (inputString == "get_json") {
          get_json();
        }
      }
      inputString = "";
    }
    else {
      inputString += char(c);
    }
  }
// Мигалка встроенным светодиодом. bl переполняется и всё сначала  
  bl += bli;
  if (bl > 128) {
    digitalWrite(LED_BUILTIN, HIGH);
  }
  else {
    digitalWrite(LED_BUILTIN, LOW);
  }
  delay(5);
}

void pwm25khzBegin() {
  TCCR2A = 0;
  TCCR2B = 0;
  TIMSK2 = 0;
  TIFR2 = 0;
  TCCR2A |= (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);
  TCCR2B |= (1 << WGM22) | (1 << CS21);
  OCR2A = 79;
  OCR2B = 0;
}

// 79 = 100%
void pwmDuty(byte pp) {
  byte ocrb;
  ocrb = map(pp,1,99,1,78);
  OCR2B = ocrb;
}
