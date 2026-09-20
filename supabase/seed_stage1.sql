-- =========================================================
-- Seed: Stage 1 ("Level 1") content
-- Run this once in the Supabase SQL Editor, after schema.sql
-- and the registration-fields migration have both been run.
--
-- Content mapping from "Stage 1.pdf":
--   - Section "Session Attendance" -> 1 session, 50 XP, admin-approved
--   - Sections 1-10 (Introduction to Robotics .. Motors & motor drivers)
--     -> 10 topics, 10 XP each, auto-approved on completion
--   - Sections 11-12 (Bluetooth controlled cars, Obstacle avoiding cars)
--     -> 2 projects, 100 XP each, admin-approved
--
-- NOTE: "Introduction to Robotics" had no body text in the source PDF
-- (just a heading) -- its `concept` below is a placeholder; replace it
-- with real material via the Supabase Table Editor whenever it's ready.
--
-- Safe to re-run: guards against duplicate inserts by title/stage.
-- =========================================================

insert into public.stages (number, title, theme)
values (1, 'Level 1', 'Robotics Fundamentals')
on conflict (number) do update set title = excluded.title, theme = excluded.theme;

-- ---------------------------------------------------------
-- Session: Session Attendance (50 XP, admin approval)
-- ---------------------------------------------------------
insert into public.sessions (stage_id, title, content, xp_value)
select
  (select id from public.stages where number = 1),
  'Session Attendance',
  'Mark your attendance for the Stage 1 orientation/kickoff session. Your instructor will verify attendance and approve this from the admin side.',
  50
where not exists (
  select 1 from public.sessions
  where stage_id = (select id from public.stages where number = 1)
    and title = 'Session Attendance'
);

-- ---------------------------------------------------------
-- Topics (10 x 10 XP, auto-approved)
-- ---------------------------------------------------------

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'Introduction to Robotics',
  'Get an overview of what robotics is and what this stage will cover.',
  $c$Content for this chapter is coming soon -- placeholder topic (no source material was provided for this heading yet).$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Introduction to Robotics'
);

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'Basic Electronics',
  'Understand voltage, current, power, resistors, Ohm''s Law, and LEDs -- the building blocks of every circuit.',
  $c$1. Voltage, Current & Power (https://youtu.be/zH-5ls0YAI0?si=OgxqKd3ML0Oj5yBS)
Voltage (Volts): the potential energy difference, or the "desire" for electrons to move from one point to another. Water analogy: voltage is like a cup of water held high up -- it has potential energy, but that doesn't mean water is moving.
Current (Amperes): the actual flow of electrons through a component. In the water analogy, current is the stream pouring out when you tip the glass.
Power (Watts): a function of both voltage and current working together to do work. High voltage with zero flow (or high flow with zero voltage) generates virtually no power.
Energy: power delivered over time. A capacitor has high power density (discharges stored energy extremely quickly); a battery has high energy density (holds more overall energy, releases it steadily over a longer period).

2. Resistors (https://youtu.be/x6jajfprWZo?si=xGUBNvMq1T-fLvBY)
Purpose: resist the flow of electric current and manage voltage/current levels across a circuit.
Key components: Resistive Material (carbon, metal film, or wire-wound core that restricts electron flow), Leads/Terminals (connectors for current to enter/exit), Encapsulation (protective ceramic/plastic coating).
Effects in a circuit: Heat Dissipation (lost energy converted to heat) and Voltage Drop (a controlled drop across the resistor's terminals, protecting sensitive components like microchips).
Common types: Fixed Resistors (static value), Variable Resistors/Potentiometers (manually adjustable), Thermistors (resistance changes with ambient temperature).

3. Ohm's Law (https://youtu.be/HsLLq6Rm5tU?si=oFtNfi63SGIIhbCq)
Current is directly proportional to Voltage: double the voltage, current doubles (resistance constant).
Current is inversely proportional to Resistance: double the resistance, current is cut in half.

4. LEDs (https://youtu.be/O8M2z2hIbag?si=MfpwWjAVn1CqlHA8)
An LED (Light Emitting Diode) converts electrical energy directly into visible light using semiconductor material. Unlike incandescent bulbs (which heat a filament until it glows), LEDs emit photons via electron movement with almost no wasted heat -- much more energy efficient.

5. Connection of LEDs, Switches and Batteries (https://youtu.be/8CGEoHSHduc?si=AwbA21fyMPrXachm)
Practical wiring of a battery, switch, and LED into a simple working circuit.$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Basic Electronics'
);

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'Tools & Workshop Skills',
  'Get comfortable with the multimeter and soldering iron -- the two tools you will use constantly.',
  $c$1. Multimeter (https://youtu.be/ts0EVc9vXcs?si=VAHfErAzgUeZid_C)

2. Soldering (https://youtu.be/QKbJxytERvg?si=LembyOcntE5HEtza)
Soldering is not just hot metal glue -- it fuses metals at the molecular level using heat as the key catalyst, to create reliable electrical connections.

3. Desoldering (https://youtu.be/N_dvf45hN6Y?si=BZJJLEWw_NGQHmCD)

4. Heat Shrink (https://youtu.be/VgnHuJGocZI?si=fWHzw7Yr-jafq3qn)$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Tools & Workshop Skills'
);

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'Breadboard & Circuit Building',
  'Learn to prototype circuits on a breadboard without soldering.',
  $c$Breadboard & Circuit Building (https://youtu.be/W6mixXsn-Vc?si=19hOvWgFo8D-igur)
Purpose: breadboards let you build and test circuits temporarily without soldering -- components can be quickly inserted, moved, or swapped.
Power Rails: long metal strips running vertically along the outer sides, designated for power (red/plus) and ground (blue/black/minus). Connecting a battery/power supply to one end gives access to power across the entire board. Note: some power rails have a split/gap in the middle, requiring jumper wires to bridge both halves.

Jumper wires (https://youtu.be/pJXCYjpq2TQ?si=l8E06Zx2FSMG3HA8)$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Breadboard & Circuit Building'
);

insert into public.topics (stage_id, title, learning_objectives, concept, hw_sw_requirements, code_example, xp_value, status)
select (select id from public.stages where number = 1),
  'Arduino Fundamentals',
  'Learn the Arduino IDE, board layout, core syntax, and how to read/write digital pins.',
  $c$Videos:
https://youtu.be/JnJIKX5J0Cc?si=okGV43s1KrbdgXzN
https://youtu.be/SX8z3-BEuWQ?si=ogRrtr8yZl-ZFKWY
https://youtu.be/ynAvySNCi-0?si=Mmpxcu9Vex71KvhW
https://youtu.be/EVDnYnAyktw?si=GNGQ4dFUMsDcCKM6
https://youtu.be/m8ov5S78AlY?si=TPGUTO5QZdKriB-2
https://youtu.be/Q5A2vsa2B-g?si=Mi0D96XMUI2zVZ2E
https://youtu.be/oOBxocRbdbo?si=M_kBWzziXQCrFWX8

Arduino IDE (Integrated Development Environment) is used for writing and uploading programs to Arduino boards, using high-level languages like C/C++ instead of low-level assembly.

Board basics: Microcontroller (coordinates input and executes your code), Analog Reference pin (supports 10-bit analog-to-digital conversion via analogRead()), Digital Pins (input/output via pinMode(), digitalRead(), digitalWrite()), Reset Button (resets all components to default), Power and Ground Pins (ground is usually 0V, the circuit's reference level), USB (protocol for uploading code and communication).

Brackets: Parentheses '( )' hold function arguments and define precedence in equations. Curly Brackets '{ }' open/close the statements inside a function.

Comments: single-line with // (rest of the line ignored by the compiler); multi-line between /* and */.

Coding screen: split into setup() (runs once, for pin modes/libraries/variables) and loop() (runs repeatedly).

pinMode(pin, mode): assigns a pin as INPUT or OUTPUT. e.g. pinMode(13, INPUT). OUTPUT mode lets a pin supply current to light an LED or drive a sensor. INPUT_PULLUP reverses the behavior of INPUT using an internal pull-up resistor.

Advantages: beginner-friendly, huge ecosystem, open-source, many board options for different needs.
Disadvantages: limited memory/processing power, weak security, limited ADC precision, not suited for hard real-time applications.$c$,
  'Arduino Uno (or compatible board), USB cable, Arduino IDE installed on your computer.',
  $code$/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
  Most Arduinos have an on-board LED on digital pin 13.
*/

// the setup function runs once when you press reset or power the board
void setup() {
  // initialize digital pin 13 as an output.
  pinMode(13, OUTPUT);
}

// the loop function runs over and over again forever
void loop() {
  digitalWrite(13, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(1000);              // wait for a second
  digitalWrite(13, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);              // wait for a second
}
$code$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Arduino Fundamentals'
);

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'ESP32 Fundamentals',
  'Understand what the ESP32 is, how it compares to Arduino Uno, and its major variants.',
  $c$Video: http://www.youtube.com/watch?v=mydCDdnSo5o&utm_source=gemini

Espressif released the ESP8266 in 2014, making Wi-Fi accessible for small projects, followed by the original dual-core ESP32 in 2016 with Bluetooth and enhanced hardware capabilities.

ESP32 vs. Arduino Uno: Arduino Uno (ATmega328P, 16 MHz) is simple and great for learning basics, while ESP32 (dual-core, up to 240 MHz) provides built-in Wi-Fi, Bluetooth, and significantly higher processing power.

ESP32 vs. ESP8266: the ESP8266 is an older, single-core chip suitable for basic Wi-Fi tasks, whereas the ESP32 family offers more processing power, modern security, and richer hardware peripherals.

ESP32-S2: native USB support and security focus, but omits Bluetooth.
ESP32-S3: dual-core with BLE, native USB, optimized for displays/cameras/vector processing/ML.
ESP32-C3: low-cost, energy-efficient single-core RISC-V chip with Wi-Fi and BLE.
ESP32-C6: adds Wi-Fi 6, BLE, and IEEE 802.15.4 radio (Zigbee, Thread, Matter for smart home ecosystems).$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'ESP32 Fundamentals'
);

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'Tinkercad',
  'Simulate Arduino circuits in the browser before building them physically.',
  $c$1. Making a simple LED: https://youtu.be/Mi1-IV0vMCw?si=GpucXG4JLXtCOMd
2. Fading a LED with Arduino: https://youtu.be/i35bBDqQn2s?si=h38Xkcoobw7aCd5P
3. Introduction to Arduino w/ TinkerCAD Circuits: https://youtu.be/3kDMYomFw5o?si=AygwSpc4JouPlFFQ$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Tinkercad'
);

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'Digital, Analog and PWM',
  'Understand the difference between digital and analog signals, and how PWM/ADC bridge the two.',
  $c$1. Digital and Analog for input and output (https://youtu.be/BMMnOAzcqoE?si=Fv3MInHLyoUiYUXd)
Analog Signal: takes any value in a continuous range (Arduino analog signals are roughly 0V-5V). Analog pins support up to ~8-10 bit resolution, so they're used for large-range input values with high accuracy.
Digital Signal: only takes discrete values, high ('1') and low ('0'). Sequences of 0s/1s form binary data -- low memory requirement, but prone to quantization error.
Arduino simulates an analog voltage output using PWM (Pulse Width Modulation) pins, marked with a tilde (~) next to the pin number.

2. PWM (https://youtu.be/5nwNKPs2gco?si=VD2v4e9V3yHIIhCV)
PWM rapidly switches a DC voltage ON and OFF. Duty Cycle (%) = (Ton / (Ton + Toff)) x 100. Adjusting the pulse width varies the average output voltage delivered to the load without wasting power as heat in current-limiting resistors.

3. ADC (https://youtu.be/EnfjYwe2A0w?si=9sk5bs95onixl0Lb)
Real-world sensors produce continuous analog signals; microcontrollers only understand binary, so an ADC translates smooth voltage into digital numbers.
Resolution: for an n-bit ADC over reference voltage Vref, step size = Vref / 2^n. A 10-bit ADC (Arduino Uno) divides 0-5V into 1024 steps (~4.88 mV/step); a 12-bit ADC divides it into 4096 steps for higher precision.
Internal ADCs (Arduino/ESP32): convenient/built-in, but can suffer noise, lower sampling speed, nonlinearity. External ADCs (e.g. ADS7816, ADS1115): higher resolution (12/16-bit), cleaner power isolation, faster sampling, connected via SPI/I2C.

4. digitalRead() & digitalWrite() (https://youtu.be/8bufqdXwCpY?si=AEh1cAEibfeybtgx)
digitalWrite: sets a pin HIGH (5V/3.3V, sourcing current) or LOW (0V, sinking current) -- used to drive LEDs, relays, transistors, trigger signals.
digitalRead: reads whether an input pin is HIGH or LOW -- used for pushbuttons, switches, PIR/obstacle sensors, digital data lines.

5. analogRead() & analogWrite() (https://youtu.be/E6nsK6oLbIo?si=gC8gawa4ykNgueKf)
analogRead: measures a continuous voltage via the ADC and returns a numeric value (0-1023 on a 10-bit ADC, e.g. 0V->0, 2.5V->511, 5V->1023). Used for potentiometers, LDRs, thermistors, flex sensors, battery voltage.
analogWrite: most microcontrollers lack a true DAC, so "analog" output is simulated with PWM -- rapidly switching HIGH/LOW and varying the duty cycle to control average voltage (0% = always off, 50% = ~2.5V average, 100% = always on).$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Digital, Analog and PWM'
);

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'Sensors',
  'Learn how IR, ultrasonic, and LDR sensors sense their environment.',
  $c$1. IR sensor (https://youtu.be/OMZacCLRt9A?si=mjcl8zWhSgP6nUlW)
An Infrared (IR) sensor emits/detects infrared light (~700nm-1mm, invisible to the eye) to sense obstacles, distance, line tracking, or ambient heat.
Active IR sensors have both an emitter (IR LED, ~940nm) and detector (photodiode/phototransistor). The IR LED continuously emits light; when an object enters the field, light reflects back to the photodiode, and an onboard comparator (e.g. LM393) compares that voltage to a threshold (set by a potentiometer) to output HIGH/LOW.
Passive IR (PIR) sensors emit no light -- they detect thermal infrared radiation naturally emitted by warm objects (people, animals, machinery) via pyroelectric elements, mainly used for motion detection in security/lighting systems.

2. Ultrasonic Sensor (https://youtu.be/KGwtit2bFyo?si=ekrmm_WwkSrs9CxH)
Measures distance by emitting high-frequency ultrasonic sound (~40 kHz) and listening for the echo -- non-contact distance measurement regardless of surface color, light, or transparency.

3. LDR Sensor (https://youtu.be/2fvXW4OEWLE?si=2Ewnogg4g6nMNS0q)
A Light Dependent Resistor's resistance varies with light intensity: light striking the semiconductor excites electrons into the conduction band, increasing conductivity and reducing resistance. Used in automatic street lights, camera light meters, automatic night lights, and intruder alarms.

4. Sensor Reading and Calibration$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Sensors'
);

insert into public.topics (stage_id, title, learning_objectives, concept, xp_value, status)
select (select id from public.stages where number = 1),
  'Motors & motor drivers',
  'Learn how DC motors, servo motors, and motor drivers work together to move a robot.',
  $c$1. Speed control of a single DC geared motor with an L298N motor driver and Arduino: https://youtu.be/r-upF9Nkt7Y?si=CN6PZq3dALcwDymj
2. Motor Drivers: https://youtu.be/PVyAcgYkzDs?si=X9NMG5EtLqHE3n1g
3. DC Gear Motors: https://youtu.be/GPVC84D5ULw?si=6B1xxr9XrdcPsAtn
4. Servo Motors: https://youtu.be/1WnGv-DPexc?si=LKbpKA_WCPWdZnj2
5. Gear Ratio, Torque, RPM, Mechanical Advantage: https://youtu.be/8AXEKKXDXNM?si=PKpShVaOpsDD0f4K$c$,
  10, 'published'
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 1) and title = 'Motors & motor drivers'
);

-- ---------------------------------------------------------
-- Projects (2 x 100 XP, admin-approved)
-- ---------------------------------------------------------

insert into public.projects (stage_id, title, requirements, instructions, xp_value)
select (select id from public.stages where number = 1),
  'Bluetooth Controlled Car',
  'Arduino/ESP32 board, HC-05/HC-06 Bluetooth module, motor driver (e.g. L298N), DC geared motors, chassis, battery pack.',
  $c$Build a small car chassis driven by DC motors through a motor driver, controlled wirelessly over Bluetooth from a phone app.
Reference videos:
https://youtu.be/gU-CZP2nIwQ?si=LJVxd1Rziycudn4y
https://youtu.be/rSCy1_GbC0w?si=ft-hfm8j8sK--jjh$c$,
  100
where not exists (
  select 1 from public.projects where stage_id = (select id from public.stages where number = 1) and title = 'Bluetooth Controlled Car'
);

insert into public.projects (stage_id, title, requirements, instructions, xp_value)
select (select id from public.stages where number = 1),
  'Obstacle Avoiding Car',
  'Arduino/ESP32 board, ultrasonic (or IR) sensor, motor driver (e.g. L298N), DC geared motors, chassis, battery pack.',
  $c$Build a car that detects obstacles using an ultrasonic or IR sensor and automatically steers around them.
Reference videos:
https://youtu.be/1n_KjpMfVT0?si=JWyMGsR63tcuKAdQ
https://youtu.be/vAi58PjUsc8?si=oWoVOz0sdZVoQUsl$c$,
  100
where not exists (
  select 1 from public.projects where stage_id = (select id from public.stages where number = 1) and title = 'Obstacle Avoiding Car'
);
