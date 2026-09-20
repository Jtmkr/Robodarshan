-- =========================================================
-- Seed: Stage 1 quizzes (5 questions each) for all 10 topics
-- and both projects. Run after seed_stage1.sql AND migration
-- 006_project_quiz_column.sql.
--
-- Shape: [{ "question": "...", "options": [...4 strings...],
--            "answer": <0-based index of correct option> }, ...]
--
-- Safe to re-run: each UPDATE just overwrites that item's quiz.
-- =========================================================

update public.topics
set quiz = $q$[
  {"question": "What are the three basic functional stages every robot follows?", "options": ["Input, Processing, Output", "Power, Control, Motion", "Design, Build, Test", "Sense, Think, Communicate"], "answer": 0},
  {"question": "Which component allows a robot to interact physically with its environment?", "options": ["Sensor", "Actuator", "Controller", "Power supply"], "answer": 1},
  {"question": "What is the role of a controller/microcontroller in a robot?", "options": ["Supplies power to the motors", "Detects light and sound", "Processes input and decides the output", "Provides mechanical structure"], "answer": 2},
  {"question": "Sensors in a robot are primarily used to:", "options": ["Move the robot", "Perceive/measure the environment", "Store energy", "Display output to a user"], "answer": 1},
  {"question": "Which of these is an example of an actuator?", "options": ["Ultrasonic sensor", "DC motor", "Potentiometer", "LDR"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Introduction to Robotics';

update public.topics
set quiz = $q$[
  {"question": "What does voltage represent in a circuit?", "options": ["The flow rate of electrons", "The potential energy difference that drives electron flow", "The resistance to current flow", "The rate of energy conversion"], "answer": 1},
  {"question": "According to Ohm's Law, if resistance doubles while voltage stays constant, current will:", "options": ["Double", "Stay the same", "Be cut in half", "Become zero"], "answer": 2},
  {"question": "What is the main purpose of a resistor in a circuit?", "options": ["Store electrical energy", "Resist current flow and control voltage/current levels", "Convert electricity into light", "Amplify the signal"], "answer": 1},
  {"question": "An LED converts electrical energy into:", "options": ["Heat only", "Sound", "Visible light", "Magnetic field"], "answer": 2},
  {"question": "Which component's resistance changes based on ambient temperature?", "options": ["Fixed resistor", "Potentiometer", "Thermistor", "LED"], "answer": 2}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Basic Electronics';

update public.topics
set quiz = $q$[
  {"question": "What does a multimeter measure?", "options": ["Only voltage", "Voltage, current, and resistance", "Only temperature", "Only frequency"], "answer": 1},
  {"question": "What is soldering primarily used for?", "options": ["Cutting wires", "Creating a strong molecular-level electrical connection between metals", "Measuring resistance", "Insulating wires"], "answer": 1},
  {"question": "What is the purpose of desoldering?", "options": ["Adding more solder to a joint", "Removing solder to disconnect or rework a component", "Testing a circuit's voltage", "Bending component leads"], "answer": 1},
  {"question": "What does heat shrink tubing do?", "options": ["Increases current flow", "Insulates and protects a soldered joint or wire when heated", "Cools down a hot soldering iron", "Measures wire diameter"], "answer": 1},
  {"question": "Why is workshop safety important when soldering?", "options": ["It's not important", "To avoid burns and handle hot tools/fumes safely", "It only affects the appearance of the joint", "It makes soldering faster"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Tools & Workshop Skills';

update public.topics
set quiz = $q$[
  {"question": "What is the main advantage of using a breadboard?", "options": ["Permanent circuit connections", "Building/testing circuits without soldering", "Higher current capacity", "Reduced circuit size"], "answer": 1},
  {"question": "What are the power rails on a breadboard used for?", "options": ["Only for holding ICs", "Distributing power (+) and ground (-) across the board", "Increasing resistance", "Storing components"], "answer": 1},
  {"question": "Why might you need a jumper wire across a breadboard's power rail?", "options": ["To measure voltage", "Some power rails have a gap/split in the middle needing a bridge", "To desolder a component", "To increase LED brightness"], "answer": 1},
  {"question": "What is a circuit diagram used for?", "options": ["Decoration", "Representing how components are electrically connected", "Measuring current", "Storing code"], "answer": 1},
  {"question": "What type of connections does a breadboard provide internally in its terminal strips?", "options": ["No connections at all", "Rows of holes electrically connected in short strips", "Permanent soldered joints", "Only USB connections"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Breadboard & Circuit Building';

update public.topics
set quiz = $q$[
  {"question": "What software is used to write and upload code to an Arduino board?", "options": ["Tinkercad", "Arduino IDE", "KiCad", "Photoshop"], "answer": 1},
  {"question": "Which function runs only once when the Arduino is powered on or reset?", "options": ["loop()", "setup()", "main()", "init()"], "answer": 1},
  {"question": "What does pinMode(13, OUTPUT) do?", "options": ["Reads a value from pin 13", "Configures pin 13 to send current out to control a component", "Deletes pin 13", "Sets pin 13 to always be off"], "answer": 1},
  {"question": "Which symbol pair is used for a single-line comment in Arduino code?", "options": ["/* */", "//", "<!-- -->", "##"], "answer": 1},
  {"question": "What does digitalWrite(pin, HIGH) do?", "options": ["Reads the pin's current voltage", "Sets the specified pin's output voltage to high (e.g. 5V)", "Deletes the pin's configuration", "Waits for one second"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Arduino Fundamentals';

update public.topics
set quiz = $q$[
  {"question": "Compared to Arduino Uno, the ESP32 offers:", "options": ["Less processing power", "Built-in Wi-Fi, Bluetooth, and much higher processing power", "No programmable pins", "Only analog input"], "answer": 1},
  {"question": "What company originally released the ESP8266 and ESP32?", "options": ["Arduino", "Espressif", "Raspberry Pi Foundation", "Intel"], "answer": 1},
  {"question": "Which ESP32 variant is noted for omitting Bluetooth but including native USB support?", "options": ["ESP32-S3", "ESP32-C3", "ESP32-S2", "ESP32-C6"], "answer": 2},
  {"question": "Which ESP32 variant adds Wi-Fi 6 and IEEE 802.15.4 support (Zigbee/Thread/Matter)?", "options": ["ESP32-C6", "ESP32-S2", "ESP32 (original)", "ESP8266"], "answer": 0},
  {"question": "The ESP32-C3 is based on which type of processor architecture?", "options": ["ARM Cortex-M4", "RISC-V", "x86", "MIPS"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'ESP32 Fundamentals';

update public.topics
set quiz = $q$[
  {"question": "What is the main purpose of Tinkercad Circuits?", "options": ["3D printing only", "Simulating and testing Arduino circuits virtually before building them", "Writing documents", "Editing photos"], "answer": 1},
  {"question": "What is one benefit of testing a circuit in Tinkercad before physical assembly?", "options": ["It costs more than physical components", "You can catch wiring/code errors without risking real hardware", "It replaces the need to ever build the real circuit", "It automatically orders components"], "answer": 1},
  {"question": "Can you write and run Arduino code within Tinkercad Circuits?", "options": ["No, it only supports breadboard layout", "Yes, it includes a code editor and simulator", "Only for ESP32 boards", "Only in a paid version"], "answer": 1},
  {"question": "What can you simulate in Tinkercad besides LEDs?", "options": ["Nothing else", "Various components like resistors, buttons, and virtual Arduino boards", "Only sound", "Only motors"], "answer": 1},
  {"question": "Tinkercad Circuits is especially useful for beginners because:", "options": ["It requires no internet connection", "It lets you learn and debug without needing physical hardware", "It is faster than a real Arduino", "It replaces the Arduino IDE entirely"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Tinkercad';

update public.topics
set quiz = $q$[
  {"question": "A digital signal can only take which values?", "options": ["Any value between 0 and 5V", "High (1) and Low (0)", "Only negative values", "Only fractional values"], "answer": 1},
  {"question": "What does PWM stand for?", "options": ["Power Wave Modulation", "Pulse Width Modulation", "Positive Wire Mapping", "Parallel Word Method"], "answer": 1},
  {"question": "A 10-bit ADC divides a 0-5V range into how many steps?", "options": ["256", "512", "1024", "4096"], "answer": 2},
  {"question": "What does the duty cycle in PWM represent?", "options": ["The total voltage of the circuit", "The percentage of time the signal stays HIGH during each cycle", "The number of pins used", "The resistance value"], "answer": 1},
  {"question": "Which Arduino pins can simulate analog output, marked with a tilde (~)?", "options": ["All digital pins", "Only analog input pins", "PWM-capable pins", "Only pin 13"], "answer": 2}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Digital, Analog and PWM';

update public.topics
set quiz = $q$[
  {"question": "What is the key difference between active and passive IR sensors?", "options": ["Active sensors emit their own IR light; passive sensors only detect existing IR/heat radiation", "Passive sensors are always more accurate", "Active sensors don't use LEDs", "There is no difference"], "answer": 0},
  {"question": "What does an ultrasonic sensor use to measure distance?", "options": ["Visible light reflection", "High-frequency sound waves and their echo", "Magnetic fields", "Infrared heat only"], "answer": 1},
  {"question": "How does an LDR's resistance change with light intensity?", "options": ["Resistance increases as light increases", "Resistance decreases as light increases", "Resistance stays constant regardless of light", "LDRs don't respond to light"], "answer": 1},
  {"question": "PIR sensors are commonly used for:", "options": ["Measuring exact distance", "Motion detection based on body heat", "Measuring voltage", "Wireless communication"], "answer": 1},
  {"question": "What does the onboard comparator (e.g. LM393) do in an active IR sensor module?", "options": ["Emits the IR light", "Compares the receiver's voltage to a threshold and outputs HIGH/LOW", "Powers the motor", "Stores sensor readings permanently"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Sensors';

update public.topics
set quiz = $q$[
  {"question": "Why is a motor driver like the L298N needed to control a DC motor from an Arduino?", "options": ["Arduino pins can't supply enough current to drive a motor directly", "It converts AC to DC", "It replaces the need for a battery", "It only works with servo motors"], "answer": 0},
  {"question": "How is speed typically controlled in a DC motor using a motor driver?", "options": ["By changing the ambient temperature", "By using PWM to vary the average voltage delivered", "By changing the motor's color", "By reversing polarity continuously"], "answer": 1},
  {"question": "What does an H-bridge circuit (like in the L298N) primarily allow?", "options": ["Only forward rotation", "Controlling both direction and speed of a DC motor", "Measuring motor temperature", "Charging the battery"], "answer": 1},
  {"question": "What determines a servo motor's output angle?", "options": ["Its resistance", "The width/duration of the control pulse it receives", "The ambient light level", "The battery voltage only"], "answer": 1},
  {"question": "In gear systems, increasing the gear ratio generally results in:", "options": ["Higher speed and lower torque", "Lower speed and higher torque", "No change in speed or torque", "Only a change in motor color"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Motors & motor drivers';

update public.projects
set quiz = $q$[
  {"question": "What module is commonly used to add Bluetooth control to an Arduino-based car?", "options": ["HC-05/HC-06", "L298N", "LM393", "DHT11"], "answer": 0},
  {"question": "What is the role of the motor driver in this project?", "options": ["Sending Bluetooth signals", "Driving the DC motors with enough current/voltage from the microcontroller's signals", "Measuring distance", "Charging the phone"], "answer": 1},
  {"question": "What typically sends the movement commands to the Bluetooth-controlled car?", "options": ["A remote infrared control only", "A smartphone app communicating over Bluetooth", "A wired USB connection", "A light sensor"], "answer": 1},
  {"question": "Why might a project like this favor the ESP32 for the physical build over a plain Arduino Uno?", "options": ["ESP32 has no Bluetooth support", "ESP32 offers more processing power and built-in wireless options", "ESP32 cannot drive motors", "ESP32 is not programmable"], "answer": 1},
  {"question": "What powers the motors and electronics in a mobile car project like this?", "options": ["A wall outlet directly", "A portable battery pack", "Solar panels only", "The Bluetooth module itself"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Bluetooth Controlled Car';

update public.projects
set quiz = $q$[
  {"question": "Which sensor is most commonly used to detect obstacles by measuring distance in this type of project?", "options": ["LDR", "Ultrasonic sensor", "Thermistor", "Potentiometer"], "answer": 1},
  {"question": "When an obstacle is detected close to the car, what should the car's logic typically do?", "options": ["Increase speed forward", "Stop and/or turn to avoid the obstacle", "Turn off completely", "Ignore the sensor reading"], "answer": 1},
  {"question": "What role does the motor driver play in an obstacle-avoiding car?", "options": ["Detecting obstacles", "Controlling the motors' direction and speed based on sensor input", "Sending Bluetooth commands", "Measuring battery voltage"], "answer": 1},
  {"question": "Why is continuous sensor reading important in this project?", "options": ["It isn't important, one reading is enough", "The car needs up-to-date distance data to react in real time", "It saves battery", "It only matters when Bluetooth is disconnected"], "answer": 1},
  {"question": "An IR sensor could also be used instead of ultrasonic for obstacle detection, but it may struggle with:", "options": ["Detecting light-colored objects only", "Certain surfaces/colors and is generally shorter range", "Working at all in daylight", "Any kind of obstacle detection"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 1) and title = 'Obstacle Avoiding Car';
