-- =========================================================
-- Seed: quizzes (5 questions each) for all Stage 2-4 topics
-- and projects. Run after seed_stages_2_3_4.sql.
-- Safe to re-run: each UPDATE just overwrites that item's quiz.
-- =========================================================

-- ===================== STAGE 2 =====================

update public.topics set quiz = $q$[
  {"question": "Which protocol uses a shared clock + data line, commonly used for sensors like IMUs?", "options": ["UART", "I2C", "SPI", "HTTP"], "answer": 1},
  {"question": "What distinguishes SPI from I2C?", "options": ["SPI uses separate MOSI/MISO/SCK lines for fast full-duplex communication", "SPI only works wirelessly", "SPI has no clock line", "SPI cannot connect multiple devices"], "answer": 0},
  {"question": "What does UART stand for?", "options": ["Universal Asynchronous Receiver/Transmitter", "Unified Analog Radio Transmission", "Universal ARM Runtime", "User Application Real-Time"], "answer": 0},
  {"question": "What is BLE primarily designed for?", "options": ["High-bandwidth video streaming", "Low-power short-range wireless communication", "Long-distance cellular data", "Wired serial communication"], "answer": 1},
  {"question": "What does hosting a web server on the ESP32 typically allow?", "options": ["The ESP32 to browse the internet", "Other devices to control/monitor the ESP32 via a browser over Wi-Fi", "The ESP32 to print documents", "Faster GPIO switching"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'ESP32 Communication & IoT';

update public.topics set quiz = $q$[
  {"question": "What is the main advantage of using arrays in embedded code?", "options": ["They eliminate the need for functions", "They let you store and process multiple related values under one name", "They automatically fix bugs", "They only work with strings"], "answer": 1},
  {"question": "What is a struct used for?", "options": ["Grouping different related variables into a custom type", "Only storing numbers", "Replacing loops", "Making code run faster automatically"], "answer": 0},
  {"question": "What does millis() return?", "options": ["Milliseconds since the board was powered on/reset", "The CPU temperature", "The battery voltage", "A random number"], "answer": 0},
  {"question": "Why are interrupts useful in robotics programming?", "options": ["They slow down the main loop intentionally", "They let the microcontroller respond immediately to an event without polling", "They replace the need for sensors", "They only work with motors"], "answer": 1},
  {"question": "What is a state machine used for?", "options": ["Managing distinct robot behaviors/modes and transitions between them", "Only reading sensor data", "Compiling code faster", "Increasing motor torque"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Intermediate Robotics Programming';

update public.topics set quiz = $q$[
  {"question": "What does an IR array commonly detect in robotics?", "options": ["Battery voltage", "A line's position relative to the robot", "Wi-Fi signal strength", "Motor RPM directly"], "answer": 1},
  {"question": "What does a rotary encoder measure?", "options": ["Ambient light", "Rotational position/speed of a shaft or wheel", "Sound level", "Magnetic north"], "answer": 1},
  {"question": "What does an IMU typically combine?", "options": ["A camera and a microphone", "An accelerometer and a gyroscope (often plus a magnetometer)", "Two ultrasonic sensors", "A battery and a charger"], "answer": 1},
  {"question": "Why is sensor calibration important?", "options": ["It's optional and rarely needed", "It corrects offsets/inaccuracies so readings reflect real-world values", "It increases the sensor's size", "It disables the sensor temporarily"], "answer": 1},
  {"question": "What is odometry used for?", "options": ["Estimating position/distance traveled from wheel rotation data", "Measuring ambient temperature", "Detecting obstacles directly", "Sending Bluetooth commands"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Intermediate Sensors';

update public.topics set quiz = $q$[
  {"question": "What is differential drive?", "options": ["A single wheel steering system", "Steering by varying the speed of two independently driven wheels", "A hydraulic braking system", "A GPS-based navigation method"], "answer": 1},
  {"question": "What does a higher gear ratio generally trade off?", "options": ["Higher speed for lower torque", "Higher torque for lower speed", "No effect on speed or torque", "Only affects battery life"], "answer": 1},
  {"question": "What does traction refer to in robot mechanics?", "options": ["The grip between wheels and surface affecting power transfer to movement", "The robot's total weight", "The wiring layout", "The color of the wheels"], "answer": 0},
  {"question": "Why does center of gravity matter in robot design?", "options": ["It has no practical effect", "A high/off-center center of gravity can make a robot unstable or tip over", "It only matters for flying robots", "It determines battery capacity"], "answer": 1},
  {"question": "What is a key factor in choosing wheels for a robot?", "options": ["Only their color", "Traction, size, and load capacity for the terrain", "Whether they are round", "Their price alone"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Robot Mechanics';

update public.topics set quiz = $q$[
  {"question": "What is the key difference between open-loop and closed-loop motor control?", "options": ["Open-loop has no feedback; closed-loop uses sensor feedback to correct behavior", "Closed-loop is always slower", "Open-loop uses encoders, closed-loop does not", "There is no difference"], "answer": 0},
  {"question": "What is encoder feedback used for?", "options": ["Measuring actual motor speed/position to correct control output", "Charging the battery", "Detecting obstacles", "Sending data over Wi-Fi"], "answer": 0},
  {"question": "What does speed matching refer to for a differential-drive robot?", "options": ["Making both drive motors run at matched speeds so the robot drives straight", "Matching the color of both motors", "Running at maximum speed always", "Synchronizing with another robot"], "answer": 0},
  {"question": "What is a basic goal of position control?", "options": ["Making a motor/mechanism reach and hold a specific target position", "Making a motor spin as fast as possible always", "Turning the motor off permanently", "Ignoring sensor input"], "answer": 0},
  {"question": "Why is closed-loop control generally more accurate than open-loop?", "options": ["It continuously corrects for real-world disturbances using feedback", "It uses less power always", "It doesn't need a motor driver", "It has no sensors"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Motor Control';

update public.topics set quiz = $q$[
  {"question": "What does the P term in PID respond to?", "options": ["The current error between setpoint and actual value", "The rate of change of the error", "The accumulated past error", "The motor's maximum speed"], "answer": 0},
  {"question": "What does the I (integral) term help correct?", "options": ["Sudden noise spikes", "Persistent steady-state error that accumulates over time", "Only the initial error", "Communication errors"], "answer": 1},
  {"question": "What does the D (derivative) term help reduce?", "options": ["Overshoot, by responding to the rate of change of error", "The proportional gain", "Battery drain", "Wiring complexity"], "answer": 0},
  {"question": "What does overshoot mean in a PID-controlled system?", "options": ["The system never reaches the setpoint", "The system output exceeds the target setpoint before settling", "The sensor fails to read data", "The motor overheats"], "answer": 1},
  {"question": "What is PID tuning?", "options": ["Adjusting the P, I, and D gains for stable, accurate, responsive control", "Replacing the motor with a faster one", "Increasing supply voltage only", "Rewriting the whole algorithm"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'PID Control';

update public.topics set quiz = $q$[
  {"question": "What sensor arrangement is typically used for line following?", "options": ["A single ultrasonic sensor", "An array of IR sensors reading reflected light beneath the robot", "A GPS module", "A microphone array"], "answer": 1},
  {"question": "Why is calibration important before running a line follower?", "options": ["It adjusts thresholds for the surface/lighting so detection is accurate", "It changes the robot's color", "It increases speed permanently", "It's not necessary"], "answer": 0},
  {"question": "What happens when the robot detects the line drifting to one side?", "options": ["Nothing changes", "Motor control adjusts wheel speeds to steer back onto the line", "The robot stops permanently", "The robot reverses randomly"], "answer": 1},
  {"question": "What is basic line following typically based on, without PID?", "options": ["Simple threshold/on-off logic based on which sensors see the line", "Complex neural networks", "GPS coordinates", "Voice commands"], "answer": 0},
  {"question": "What could cause a line follower to lose the line at sharp turns?", "options": ["Insufficient sensor array width or slow reaction time", "Too much battery charge", "Too many Wi-Fi networks nearby", "The line being too dark"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Line Follower';

update public.topics set quiz = $q$[
  {"question": "In a PID line follower, what does error typically represent?", "options": ["The robot's battery level", "The line's position offset from the center of the sensor array", "The Wi-Fi signal strength", "The ambient temperature"], "answer": 1},
  {"question": "How is the PID output typically applied to the motors?", "options": ["It's ignored", "Added/subtracted from a base speed to correct each wheel's speed", "It only controls the robot's color", "It stops both motors"], "answer": 1},
  {"question": "What can happen if the D gain is too high in a line follower?", "options": ["The robot becomes overly sensitive to noise and jitters", "The robot always drives perfectly straight", "The battery drains instantly", "The line becomes invisible"], "answer": 0},
  {"question": "Why might a line follower need re-tuning on a different surface?", "options": ["PID gains suited to one surface/lighting may not suit another", "PID never needs tuning", "The track color doesn't matter", "Only firmware version matters"], "answer": 0},
  {"question": "What is motor-speed correction in this context?", "options": ["Adjusting left/right motor speeds from the PID output to steer the robot", "Replacing the motors", "Increasing supply voltage", "Ignoring sensor data"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'PID Line Follower';

update public.topics set quiz = $q$[
  {"question": "What does junction detection allow a maze-solving robot to do?", "options": ["Recognize points where it must decide which path to take", "Detect its own battery level", "Detect Wi-Fi routers", "Measure ambient light"], "answer": 0},
  {"question": "What is a dead end in maze solving?", "options": ["A path that leads nowhere further, requiring backtracking", "The starting point of the maze", "The fastest path", "A charging station"], "answer": 0},
  {"question": "Why does a maze solver record the path it takes?", "options": ["To later determine and use the shortest path", "To increase its speed automatically", "To reduce battery drain permanently", "It's not necessary"], "answer": 0},
  {"question": "What is a simple strategy so a maze solver never gets permanently lost?", "options": ["A wall-following rule (e.g. always turn left at a junction)", "Randomly stopping", "Ignoring all sensors", "Driving at maximum speed always"], "answer": 0},
  {"question": "What does shortest-path introduction typically build toward?", "options": ["Finding the most efficient route once the maze has been mapped", "Making the robot heavier", "Increasing sensor count only", "Removing the need for sensors entirely"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Maze Solver';

update public.topics set quiz = $q$[
  {"question": "What is a schematic in PCB design?", "options": ["The diagram showing how components are electrically connected", "The physical 3D shape of the board", "The manufacturer's invoice", "The robot's code"], "answer": 0},
  {"question": "What does DRC stand for in PCB design tools?", "options": ["Design Rule Check", "Direct Resistance Control", "Digital Router Configuration", "Dual Rail Circuit"], "answer": 0},
  {"question": "What is a Gerber file used for?", "options": ["Writing Arduino code", "The standard format sent to a manufacturer to fabricate the PCB", "Measuring voltage", "3D printing enclosures"], "answer": 1},
  {"question": "What does layout/routing refer to in PCB design?", "options": ["Placing components and drawing the copper traces connecting them", "Writing the schematic text only", "Choosing wire colors for breadboarding", "Testing the code"], "answer": 0},
  {"question": "Which of these are PCB design software mentioned in this topic?", "options": ["KiCad and EasyEDA", "Photoshop and Illustrator", "Excel and Word", "Arduino IDE and Tinkercad"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'PCB Design';

update public.topics set quiz = $q$[
  {"question": "What is a power budget in robot design?", "options": ["The estimated total current/power draw used to size the battery/supply", "The robot's purchase cost", "The Wi-Fi bandwidth used", "The PCB's physical size"], "answer": 0},
  {"question": "What is the purpose of a voltage regulator?", "options": ["To provide a stable, defined output voltage from a varying input", "To increase the robot's speed", "To store data", "To detect obstacles"], "answer": 0},
  {"question": "What is a buck converter?", "options": ["A type of DC-DC converter that steps voltage down efficiently", "A type of motor", "A wireless communication protocol", "A sensor for line following"], "answer": 0},
  {"question": "What does BMS stand for?", "options": ["Battery Management System", "Basic Motor Speed", "Bluetooth Module Setup", "Board Mounting System"], "answer": 0},
  {"question": "Why is estimating motor current important?", "options": ["It's not important", "Undersizing the supply can cause voltage drops or damage", "It only matters for the display", "It affects Wi-Fi range only"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Power Systems';

update public.topics set quiz = $q$[
  {"question": "What is a common cause of erratic sensor readings?", "options": ["Needing recalibration or dealing with electrical noise", "The robot being too fast", "Using too many LEDs", "The code being too short"], "answer": 0},
  {"question": "What does motor matching address when a robot drives crooked?", "options": ["Differences in speed/response between the left and right motors", "The color of the motors", "The battery brand", "The Wi-Fi signal"], "answer": 0},
  {"question": "What can cause encoder errors?", "options": ["Misalignment, electrical noise, or missed pulses in the signal", "Too much sunlight only", "Using the wrong programming language", "Overcharging the battery"], "answer": 0},
  {"question": "What is a good first step when debugging a communication issue?", "options": ["Immediately replace the microcontroller", "Check connections, settings, and power to the module", "Ignore it and continue", "Increase motor speed"], "answer": 1},
  {"question": "What is a typical power issue symptom in a malfunctioning robot?", "options": ["Random resets/brownouts under load from insufficient current supply", "The robot becoming lighter", "The Wi-Fi getting faster", "The code compiling faster"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Robot Debugging';

update public.projects set quiz = $q$[
  {"question": "What two main capabilities does the Stage 02 Challenge combine?", "options": ["Bluetooth control and obstacle avoidance", "PID-tuned line following and maze solving", "Voice control and GPS navigation", "3D printing and PCB design"], "answer": 1},
  {"question": "Why is PID tuning particularly important for this challenge?", "options": ["It's not needed", "It allows smooth, accurate line-following needed to navigate the maze reliably", "It only affects the robot's color", "It replaces the need for sensors"], "answer": 1},
  {"question": "What does adding encoder-based speed control improve?", "options": ["The robot's Bluetooth range", "Consistency of movement/turns via direct wheel-speed feedback", "The maze's difficulty", "The battery's capacity"], "answer": 1},
  {"question": "Why does this project specify implementation on ESP32?", "options": ["ESP32 is required for basic Arduino functions", "To leverage higher processing power and wireless features", "ESP32 cannot run motors", "It's arbitrary and has no benefit"], "answer": 1},
  {"question": "What is a good testing strategy before attempting the full maze?", "options": ["Skip testing and go straight to the maze", "Test and tune the line follower on a simple track first", "Only test in the dark", "Test without any sensors connected"], "answer": 1}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 2) and title = 'Stage 02 Challenge';

-- ===================== STAGE 3 =====================

update public.topics set quiz = $q$[
  {"question": "What does FreeRTOS add to ESP32 development?", "options": ["A real-time operating system enabling multitasking between tasks", "A new programming language", "A Bluetooth-only protocol", "A PCB layout tool"], "answer": 0},
  {"question": "What is the benefit of hardware timers/interrupts on advanced ESP32 projects?", "options": ["Precise timing of events without blocking the main program", "They replace the need for sensors", "They increase battery capacity", "They only work with Wi-Fi"], "answer": 0},
  {"question": "What does ADC do in this context?", "options": ["Converts continuous analog voltage into a digital value the microcontroller can read", "Converts digital signals into sound", "Controls motor direction", "Manages Bluetooth pairing"], "answer": 0},
  {"question": "What is multitasking in an embedded RTOS context?", "options": ["Running multiple tasks that appear to execute concurrently, scheduled by the RTOS", "Running one task forever", "Only possible on desktop computers", "The same as multithreading in a web browser"], "answer": 0},
  {"question": "Why use PWM in advanced embedded systems?", "options": ["To simulate analog output/control power delivered to a load", "To store sensor data permanently", "To detect obstacles", "To increase Wi-Fi range"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Embedded Systems';

update public.topics set quiz = $q$[
  {"question": "What is sensor fusion?", "options": ["Combining data from multiple sensors to get a more accurate/reliable estimate", "Using only one sensor at a time", "Physically merging two sensors into one chip", "A type of motor driver"], "answer": 0},
  {"question": "What does a magnetometer measure?", "options": ["Magnetic field direction, often used for heading/compass estimation", "Air pressure", "Distance to obstacles", "Battery voltage"], "answer": 0},
  {"question": "What is a barometer used for in robotics?", "options": ["Estimating altitude from air pressure changes", "Measuring wheel speed", "Detecting light levels", "Reading Wi-Fi signal strength"], "answer": 0},
  {"question": "What is the basic idea behind a Kalman filter?", "options": ["Optimally combining noisy sensor measurements and a motion model to estimate state", "A method to increase motor torque", "A way to compress images", "A wireless communication protocol"], "answer": 0},
  {"question": "Why combine IMU data with GPS or encoders instead of using IMU alone?", "options": ["IMU drifts over time, so fusing with other sensors corrects accumulated error", "IMU is always perfectly accurate alone", "GPS works better indoors", "It reduces cost"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Sensors & Sensor Fusion';

update public.topics set quiz = $q$[
  {"question": "What do coordinate frames represent in robot kinematics?", "options": ["Reference systems used to describe positions/orientations of the robot and its parts", "Only the robot's color scheme", "The robot's power supply", "A type of sensor"], "answer": 0},
  {"question": "What is forward kinematics?", "options": ["Computing the robot's/end effector's position from known joint/wheel parameters", "Computing required joint values to reach a target position", "Measuring battery voltage", "Detecting obstacles"], "answer": 0},
  {"question": "What is inverse kinematics?", "options": ["Computing the robot's position from joint parameters", "Computing the required joint/wheel parameters to reach a desired position", "A type of sensor fusion", "A PCB design step"], "answer": 1},
  {"question": "What do transformation matrices allow you to do?", "options": ["Convert coordinates between different reference frames (rotation/translation)", "Store sensor calibration data only", "Compile robot code faster", "Increase motor torque"], "answer": 0},
  {"question": "In differential-drive kinematics, what determines the robot's turning behavior?", "options": ["The difference in speed between the left and right wheels", "The robot's total weight", "The battery brand", "The Wi-Fi signal strength"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Robot Kinematics';

update public.topics set quiz = $q$[
  {"question": "What does feedforward control add on top of feedback (PID) control?", "options": ["A predictive term based on a known model, applied before error is measured", "Nothing, it's the same as PID", "Only manual control", "A GPS correction"], "answer": 0},
  {"question": "What is cascaded control?", "options": ["Nesting multiple control loops (e.g. an inner fast loop and outer slower loop)", "Running PID only once", "A way to wire multiple motors in series", "A sensor fusion technique"], "answer": 0},
  {"question": "What is the basic idea of state-space representation in control?", "options": ["Describing a system's dynamics using a set of state variables and matrix equations", "A way to store robot code in the cloud", "A type of PCB layout", "A wireless protocol"], "answer": 0},
  {"question": "Why is stability analysis important in advanced control?", "options": ["To ensure the system's response doesn't grow unbounded/oscillate destructively", "To make the robot heavier", "To increase Wi-Fi range", "It's not important"], "answer": 0},
  {"question": "Compared to basic PID, what is 'advanced PID' typically about?", "options": ["Refinements like anti-windup, filtering, and better tuning for real-world robustness", "Removing the derivative term entirely", "Only running on ROS 2", "Ignoring the setpoint"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Control';

update public.topics set quiz = $q$[
  {"question": "What does thresholding do in image processing?", "options": ["Converts a grayscale image into binary (black/white) based on a pixel value cutoff", "Increases image resolution", "Adds color to a grayscale image", "Compresses a video file"], "answer": 0},
  {"question": "What is OpenCV?", "options": ["A popular open-source computer vision library", "A type of camera sensor", "A robot operating system", "A PCB design tool"], "answer": 0},
  {"question": "What do contours represent in image processing?", "options": ["Curves joining continuous points along a boundary of similar intensity/color", "The camera's frame rate", "The image file size", "A type of sensor noise"], "answer": 0},
  {"question": "Why is camera calibration necessary for accurate computer vision?", "options": ["To correct lens distortion and determine the camera's intrinsic parameters", "To change the camera's color to grayscale permanently", "To increase battery life", "It's not necessary"], "answer": 0},
  {"question": "What is the difference between RGB and grayscale images?", "options": ["RGB has three color channels; grayscale has a single intensity channel", "Grayscale has more data than RGB", "They are identical formats", "RGB is only used for video, not still images"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Computer Vision';

update public.topics set quiz = $q$[
  {"question": "What is a ROS 2 'node'?", "options": ["An independent process that performs computation and communicates with other nodes", "A type of sensor", "A PCB component", "A Wi-Fi router"], "answer": 0},
  {"question": "How do ROS 2 nodes typically exchange streaming data?", "options": ["Via publish/subscribe on topics", "Only via direct function calls", "Only via email", "Via Bluetooth pairing only"], "answer": 0},
  {"question": "What is the difference between a ROS 2 service and a topic?", "options": ["A service is a request/response call; a topic is continuous publish/subscribe", "They are identical", "A topic is only for images", "A service cannot return data"], "answer": 0},
  {"question": "What are ROS 2 'actions' typically used for?", "options": ["Long-running tasks with feedback and the ability to cancel, like navigation goals", "Only for logging errors", "Only for reading sensor data once", "Compiling code"], "answer": 0},
  {"question": "What is the purpose of a ROS 2 launch file?", "options": ["Starting and configuring multiple nodes/parameters together in one command", "Storing camera images", "Writing PCB schematics", "Charging the robot's battery"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'ROS 2 Fundamentals';

update public.topics set quiz = $q$[
  {"question": "What is Gazebo primarily used for?", "options": ["Physics-based robot simulation", "Writing Arduino code", "PCB layout", "Battery management"], "answer": 0},
  {"question": "What is RViz used for in ROS?", "options": ["3D visualization of robot state, sensor data, and planning information", "Compiling C++ code", "Manufacturing PCBs", "Charging batteries"], "answer": 0},
  {"question": "What does URDF describe?", "options": ["A robot's physical structure (links, joints, geometry) in XML", "A wireless communication protocol", "A type of battery", "A motor driver circuit"], "answer": 0},
  {"question": "Why use Xacro with URDF?", "options": ["To simplify/parameterize URDF files using macros instead of repeating XML", "To increase motor torque", "To reduce Wi-Fi latency", "To detect obstacles"], "answer": 0},
  {"question": "What is a key benefit of simulating a robot in Gazebo before real hardware testing?", "options": ["Testing algorithms safely without risking damage to physical hardware", "It requires no computer at all", "It replaces the need for any real testing ever", "It only works for aerial robots"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Robot Simulation';

update public.topics set quiz = $q$[
  {"question": "What is localization in robotics?", "options": ["Determining the robot's position and orientation within a known environment", "Designing the robot's PCB", "Choosing the robot's programming language", "Assembling the robot's chassis"], "answer": 0},
  {"question": "What does AMCL stand for/do in ROS-based localization?", "options": ["Adaptive Monte Carlo Localization -- a particle-filter-based localization method", "A type of motor driver", "A PCB manufacturing process", "A Bluetooth protocol"], "answer": 0},
  {"question": "Why fuse IMU and GPS data for localization?", "options": ["To combine GPS's absolute position with IMU's high-rate motion data for smoother, more robust estimates", "GPS alone is always perfectly accurate indoors", "IMU alone never drifts", "It's required by law"], "answer": 0},
  {"question": "What is odometry-based localization prone to over time?", "options": ["Accumulated drift/error without external correction", "Getting more accurate the longer it runs unaided", "No error at all", "Only working outdoors"], "answer": 0},
  {"question": "What role does a Kalman filter play in localization?", "options": ["Fusing predicted motion with noisy sensor measurements to estimate the true state", "Only compressing camera images", "Only controlling motor speed", "Designing PCB traces"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Localization';

update public.topics set quiz = $q$[
  {"question": "What does SLAM stand for?", "options": ["Simultaneous Localization and Mapping", "Sensor Learning and Motor Control", "System Level Autonomous Movement", "Static Localization and Measurement"], "answer": 0},
  {"question": "Why is SLAM considered a 'chicken-and-egg' problem?", "options": ["Building a map requires knowing position, and knowing position requires a map -- both are solved together", "It requires two robots working together", "It only works with cameras", "It has no real challenge"], "answer": 0},
  {"question": "What sensor is commonly used for 2D SLAM?", "options": ["A 2D LiDAR scanning the environment", "A microphone", "A thermometer", "A battery voltage sensor"], "answer": 0},
  {"question": "What is the output of a mapping process typically used for?", "options": ["Enabling path planning and navigation within the mapped environment", "Increasing battery capacity", "Replacing the need for any sensors", "Only for display purposes with no other use"], "answer": 0},
  {"question": "What is a key challenge in map building over long runs?", "options": ["Accumulated error requiring loop closure to correct drift", "Maps never need correction once built", "It only works in a straight line", "It requires no computation"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Mapping & SLAM';

update public.topics set quiz = $q$[
  {"question": "What do BFS and DFS have in common?", "options": ["Both are graph/grid search algorithms for exploring paths", "Both guarantee the shortest path in all cases", "Both are motor control algorithms", "Both are sensor fusion techniques"], "answer": 0},
  {"question": "What does Dijkstra's algorithm guarantee (with non-negative edge weights)?", "options": ["The shortest path from a start node to all other nodes", "The fastest possible robot speed", "The lowest possible power consumption", "A collision-free trajectory automatically"], "answer": 0},
  {"question": "How does A* improve on Dijkstra's algorithm?", "options": ["It uses a heuristic to guide the search toward the goal faster", "It ignores edge weights entirely", "It only works in 1D", "It cannot find the shortest path"], "answer": 0},
  {"question": "What is the difference between global and local path planning?", "options": ["Global plans the overall route on a known map; local reacts to immediate/dynamic obstacles", "They are the same thing", "Local planning only works for aerial robots", "Global planning ignores the map entirely"], "answer": 0},
  {"question": "Why is obstacle avoidance often layered on top of a global plan?", "options": ["To safely react to unexpected/dynamic obstacles not present in the original map", "To make the robot slower on purpose", "To disable all sensors", "It has no real purpose"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Path Planning & Navigation';

update public.topics set quiz = $q$[
  {"question": "What capabilities does autonomous navigation typically combine?", "options": ["Localization, mapping, and path planning together", "Only manual remote control", "Only PCB design", "Only battery management"], "answer": 0},
  {"question": "Why is a robust state estimate important for autonomous navigation?", "options": ["Incorrect position estimates lead to poor navigation decisions and potential collisions", "It has no effect on navigation", "Only the motor speed matters", "State estimation is only needed for drones"], "answer": 0},
  {"question": "What happens if a navigating robot's map becomes outdated?", "options": ["It may plan through paths that no longer exist or miss new obstacles", "Nothing, maps never need updating", "The robot automatically fixes the map with no sensors", "Navigation improves automatically"], "answer": 0},
  {"question": "What is a common fallback behavior when a planned path becomes blocked?", "options": ["Re-planning a new path or invoking local obstacle avoidance", "Stopping forever with no recovery", "Deleting the map permanently", "Ignoring the obstacle and continuing"], "answer": 0},
  {"question": "Why combine local and global planning in a real autonomous system?", "options": ["Global gives an efficient overall route; local handles real-time obstacles the map didn't have", "Only one is ever needed", "Local planning replaces localization entirely", "Global planning reacts to sensors in real time"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Autonomous Navigation';

update public.topics set quiz = $q$[
  {"question": "What is the basic goal of a classification model in robotics AI?", "options": ["Assigning an input (e.g. an image) to one of several predefined categories", "Controlling motor voltage directly", "Designing a PCB layout", "Managing battery charge cycles"], "answer": 0},
  {"question": "What is 'inference' in a machine learning context?", "options": ["Running a trained model on new data to get a prediction", "Training a model from scratch", "Collecting raw sensor data only", "Writing the model's source code"], "answer": 0},
  {"question": "Why might a robot use object detection from a neural network?", "options": ["To identify and locate specific objects in its camera view for decision-making", "To increase its battery life", "To design its own PCB", "To reduce its own weight"], "answer": 0},
  {"question": "What is a neural network loosely inspired by?", "options": ["The structure of interconnected neurons in a brain", "A PCB trace layout", "A gear train", "A Kalman filter"], "answer": 0},
  {"question": "Why is AI/ML often combined with traditional robotics techniques rather than replacing them?", "options": ["Classical methods (kinematics, control, planning) remain reliable and efficient where ML isn't necessary", "ML always outperforms every classical method", "Classical robotics no longer works", "AI cannot be used with sensors"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'AI/ML for Robotics';

update public.topics set quiz = $q$[
  {"question": "What is a multirotor drone?", "options": ["An aircraft lifted and propelled by multiple rotors (e.g. quadcopter)", "A wheeled ground robot", "A type of underwater robot", "A stationary robotic arm"], "answer": 0},
  {"question": "What does an ESC (Electronic Speed Controller) do in a drone?", "options": ["Controls the speed of a brushless (BLDC) motor based on the flight controller's signal", "Stores flight logs", "Detects obstacles", "Provides GPS position"], "answer": 0},
  {"question": "What is the role of the flight controller in a drone?", "options": ["Processing sensor data (IMU, barometer, GPS) to stabilize and control flight", "Only storing video footage", "Only charging the battery", "Only handling Wi-Fi communication"], "answer": 0},
  {"question": "What do PX4 and ArduPilot have in common?", "options": ["Both are popular open-source autopilot/flight-control software stacks", "Both are motor types", "Both are PCB manufacturers", "Both are sensor brands"], "answer": 0},
  {"question": "Why is a 'simulation-first' workflow recommended for drone development?", "options": ["It lets you test flight logic safely before risking a real, potentially expensive crash", "Simulations are required by law before any flight", "It removes the need for a flight controller entirely", "It only works for ground robots"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Introduction to Drones';

update public.projects set quiz = $q$[
  {"question": "What is the core deliverable of the ROS 2 Autonomous Robot project?", "options": ["A robot that uses ROS 2 nodes for sensing, localization, and navigation autonomously", "A remote-controlled car with no autonomy", "A PCB design only, no robot", "A drone with manual-only control"], "answer": 0},
  {"question": "Why use ROS 2 rather than writing one monolithic program for this project?", "options": ["ROS 2's node-based architecture makes it easier to develop, test, and reuse individual components", "ROS 2 is required by law for all robots", "Monolithic programs are always faster", "ROS 2 removes the need for sensors"], "answer": 0},
  {"question": "Which tool would you likely use to visualize this robot's sensor data and planned path?", "options": ["RViz", "A PCB schematic editor", "A spreadsheet application", "A video editor"], "answer": 0},
  {"question": "Why is simulation (e.g. Gazebo) useful before deploying on the real robot?", "options": ["It allows safe testing of navigation logic without risking real hardware", "It replaces the need for any real robot at all", "It's required to charge the battery", "It only works for computer vision"], "answer": 0},
  {"question": "What combination of capabilities does this project primarily test?", "options": ["Localization, mapping/navigation, and ROS 2 system integration", "Only PCB design skills", "Only motor wiring", "Only battery selection"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'ROS 2 Autonomous Robot';

update public.projects set quiz = $q$[
  {"question": "What is the core deliverable of the Vision-Based Robot project?", "options": ["A robot that uses computer vision to make navigation/decision choices", "A robot controlled purely by a joystick", "A robot with no camera at all", "A stationary robotic arm"], "answer": 0},
  {"question": "Which library would most likely be used for the vision processing in this project?", "options": ["OpenCV", "KiCad", "FreeRTOS", "AMCL only"], "answer": 0},
  {"question": "Why might camera calibration matter for this project?", "options": ["Uncalibrated lens distortion can throw off object position/size estimates", "Calibration only affects audio quality", "It has no effect on vision accuracy", "It is only needed for LiDAR"], "answer": 0},
  {"question": "What is a simple example of a vision-based decision this robot might make?", "options": ["Following a colored line/object or avoiding a detected obstacle", "Charging its own battery automatically", "Designing its own PCB", "Compiling its own firmware"], "answer": 0},
  {"question": "Why test the vision pipeline under different lighting conditions?", "options": ["Thresholding/detection accuracy can vary significantly with lighting changes", "Lighting never affects camera-based detection", "Only night testing matters", "Cameras work identically in all lighting"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Vision-Based Robot';

update public.projects set quiz = $q$[
  {"question": "What is the Stage 03 Capstone meant to demonstrate?", "options": ["End-to-end mastery of Stage 3 skills through one chosen advanced build", "Only basic Arduino blink examples", "Only PCB soldering skills", "Only merchandise design"], "answer": 0},
  {"question": "Which of these is NOT one of the listed Stage 03 Capstone options?", "options": ["Autonomous rover", "Vision-based robot", "Basic LED blink circuit", "Robotic arm + vision"], "answer": 2},
  {"question": "Why does the capstone allow choosing between multiple project options?", "options": ["To let students specialize in the area (autonomy, vision, aerial, manipulation) that most interests them", "Because only one option actually works", "To make grading impossible", "Because the other options are optional readings only"], "answer": 0},
  {"question": "What skill areas would an 'autonomous drone' capstone combine?", "options": ["Aerial robotics, state estimation, and autonomous navigation", "Only PCB layout", "Only merchandise design", "Only line-following logic"], "answer": 0},
  {"question": "Why is system integration emphasized in a capstone project?", "options": ["Combining mechanical, electronic, and software subsystems reliably is itself a major engineering challenge", "Integration is trivial and not worth practicing", "Only one subsystem ever needs to work", "Capstones don't require integration"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 3) and title = 'Stage 03 Capstone';

-- ===================== STAGE 4 =====================

update public.topics set quiz = $q$[
  {"question": "Why is C++ commonly used in professional robotics software?", "options": ["It offers high performance and low-level control needed for real-time robotics", "It cannot interface with hardware", "It's the only language ROS supports", "It is exclusively used for web development"], "answer": 0},
  {"question": "What is the main purpose of using Git/GitHub in a robotics project?", "options": ["Version control and collaboration on code changes", "Controlling motor speed", "Designing PCBs", "Managing battery charge"], "answer": 0},
  {"question": "What does Docker provide for robotics software development?", "options": ["Containerized, reproducible environments for running software consistently", "A physical robot chassis", "A motor driver circuit", "A type of sensor"], "answer": 0},
  {"question": "Why is software architecture planning important in larger robotics projects?", "options": ["It keeps complex systems organized, maintainable, and easier to extend", "It has no real benefit for small teams", "It replaces the need for testing", "It only matters for PCB design"], "answer": 0},
  {"question": "Why is Linux commonly used as the OS for robotics computers (e.g. running ROS)?", "options": ["It offers strong support for real-time performance, open-source tooling, and ROS compatibility", "It cannot run any robotics software", "It is the only OS that supports Wi-Fi", "It is required by all microcontrollers"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Robotics Software';

update public.topics set quiz = $q$[
  {"question": "What do TF/TF2 manage in ROS 2?", "options": ["Coordinate frame transformations between different parts of a robot over time", "Motor firmware updates", "PCB trace routing", "Battery charge levels"], "answer": 0},
  {"question": "What is a lifecycle node in ROS 2?", "options": ["A node with managed states (e.g. configure, activate) for more controlled startup/shutdown", "A node that never stops running", "A type of sensor driver only", "A PCB manufacturing step"], "answer": 0},
  {"question": "Why might a project define custom ROS 2 messages?", "options": ["To represent data structures specific to the project that built-in message types don't cover", "Custom messages are required for every ROS 2 project", "To avoid using topics entirely", "Because built-in messages don't exist"], "answer": 0},
  {"question": "What is the purpose of ROS 2 Control?", "options": ["A framework for standardizing robot hardware interfaces and controllers", "A tool for PCB layout", "A battery charging protocol", "A camera calibration tool"], "answer": 0},
  {"question": "Why use parameters in ROS 2 nodes instead of hardcoding values?", "options": ["Parameters let you reconfigure node behavior without changing/recompiling code", "Parameters make code run faster automatically", "Parameters are required for topics to work at all", "Hardcoding is always preferred in ROS 2"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Advanced ROS 2';

update public.topics set quiz = $q$[
  {"question": "What do DH (Denavit-Hartenberg) parameters describe?", "options": ["A standardized way to describe the geometry of a robotic manipulator's links and joints", "Battery specifications", "PCB trace widths", "Wi-Fi signal parameters"], "answer": 0},
  {"question": "What is a Jacobian used for in manipulator kinematics?", "options": ["Relating joint velocities to end-effector velocity (and vice versa)", "Measuring battery voltage", "Designing PCB layouts", "Compressing camera images"], "answer": 0},
  {"question": "What is a kinematic singularity?", "options": ["A configuration where the manipulator loses one or more degrees of freedom of motion", "A type of sensor failure", "A battery fault condition", "A Wi-Fi connectivity issue"], "answer": 0},
  {"question": "What does a manipulator's 'workspace' refer to?", "options": ["The set of all positions/orientations its end effector can reach", "Its total weight", "Its PCB layout area", "Its battery capacity"], "answer": 0},
  {"question": "What is trajectory generation concerned with?", "options": ["Planning a smooth path of positions/velocities/accelerations over time for the manipulator to follow", "Only the final target position", "PCB routing", "Camera calibration"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Robot Kinematics';

update public.topics set quiz = $q$[
  {"question": "What is the core idea of an LQR (Linear Quadratic Regulator) controller?", "options": ["Finding an optimal control law that minimizes a cost balancing state error and control effort", "A type of motor driver hardware", "A wireless communication protocol", "A PCB design rule"], "answer": 0},
  {"question": "What does MPC (Model Predictive Control) do differently from simple PID?", "options": ["It optimizes control actions over a predicted future horizon using a system model", "It ignores the system model entirely", "It only works for aerial robots", "It cannot handle constraints"], "answer": 0},
  {"question": "What is feedback linearization used for?", "options": ["Transforming a nonlinear system into an equivalent linear one via feedback, to simplify control design", "Increasing battery voltage", "Designing PCB schematics", "Calibrating cameras"], "answer": 0},
  {"question": "Why might adaptive control be used over fixed-gain control?", "options": ["It adjusts control parameters in real time as system dynamics or conditions change", "It never needs tuning at all", "It removes the need for any sensors", "It is simpler than PID"], "answer": 0},
  {"question": "What does robust control aim to achieve?", "options": ["Maintaining acceptable performance despite model uncertainty or disturbances", "Guaranteeing zero error under all conditions with no tradeoffs", "Eliminating the need for feedback", "Only working in simulation, never on real hardware"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Control';

update public.topics set quiz = $q$[
  {"question": "What additional information does a depth camera provide over a regular RGB camera?", "options": ["Distance/depth information for each pixel, enabling 3D perception", "Only higher resolution color images", "Only infrared night vision", "Only audio data"], "answer": 0},
  {"question": "What is a point cloud?", "options": ["A set of 3D points representing the surfaces of objects in a scene", "A type of Wi-Fi network topology", "A PCB component", "A battery specification"], "answer": 0},
  {"question": "Why is LiDAR processing useful in advanced perception?", "options": ["It provides precise distance measurements used for mapping, detection, and obstacle avoidance", "It only measures temperature", "It replaces the need for any cameras in all cases", "It cannot be used outdoors"], "answer": 0},
  {"question": "What is the goal of 3D reconstruction?", "options": ["Building a 3D model of a scene/object from sensor data (e.g. depth camera or LiDAR)", "Only recording 2D video", "Charging batteries faster", "Designing PCB layouts"], "answer": 0},
  {"question": "What does object detection/tracking add beyond simple object detection alone?", "options": ["Following a detected object's identity and position across successive frames over time", "Nothing, they are identical", "It only works on static images", "It removes the need for a camera"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Perception';

update public.topics set quiz = $q$[
  {"question": "What is the key difference between EKF and a standard Kalman filter?", "options": ["EKF (Extended Kalman Filter) linearizes nonlinear system models to apply Kalman filtering", "EKF cannot be used for localization", "EKF only works with cameras", "There is no difference"], "answer": 0},
  {"question": "What is visual odometry?", "options": ["Estimating a robot's motion by analyzing sequential camera images", "Estimating motion using only wheel encoders", "A PCB layout technique", "A battery management method"], "answer": 0},
  {"question": "What distinguishes visual SLAM from LiDAR SLAM?", "options": ["Visual SLAM uses camera imagery; LiDAR SLAM uses laser range-finding data", "They are the exact same technique", "Visual SLAM cannot build maps", "LiDAR SLAM only works indoors"], "answer": 0},
  {"question": "Why might a UKF (Unscented Kalman Filter) be preferred over an EKF in some cases?", "options": ["It can better handle strong nonlinearities without requiring analytical linearization", "It requires no sensors at all", "It is always simpler to implement than EKF", "It only works for 1D systems"], "answer": 0},
  {"question": "What is the benefit of multi-sensor fusion in advanced localization?", "options": ["Combining complementary sensors compensates for each one's individual weaknesses", "Using more sensors always increases error", "It's only useful for a single sensor type", "It removes the need for any filtering"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Localization & SLAM';

update public.topics set quiz = $q$[
  {"question": "What is the key advantage of RRT (Rapidly-exploring Random Tree) for path planning?", "options": ["It efficiently explores high-dimensional or complex spaces by random sampling", "It always finds the mathematically shortest path", "It only works in 2D grids", "It requires no computation"], "answer": 0},
  {"question": "How does RRT* improve on basic RRT?", "options": ["It incrementally rewires the tree to asymptotically approach an optimal path", "It removes randomness entirely", "It only works for aerial robots", "It cannot handle obstacles"], "answer": 0},
  {"question": "What is D* commonly used for compared to A*?", "options": ["Efficiently re-planning paths when the environment changes dynamically", "Only static, unchanging environments", "PCB routing", "Battery optimization"], "answer": 0},
  {"question": "What does dynamic obstacle avoidance need to account for that static planning doesn't?", "options": ["Obstacles that move, requiring continuous re-evaluation of the path", "Only obstacles that never move", "Only the robot's own battery level", "Only Wi-Fi signal strength"], "answer": 0},
  {"question": "What is trajectory planning concerned with, beyond simple path planning?", "options": ["Timing, velocity, and acceleration profiles along the path, not just the geometric route", "Only the robot's final resting position", "Only PCB layout", "Only camera calibration"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Path Planning';

update public.topics set quiz = $q$[
  {"question": "What does DOF (Degrees of Freedom) refer to for a robotic arm?", "options": ["The number of independent ways the arm can move/articulate", "The arm's total weight", "The arm's battery voltage", "Its Wi-Fi range"], "answer": 0},
  {"question": "What is an end effector?", "options": ["The tool or device at the end of a robotic arm that interacts with the environment (e.g. a gripper)", "The arm's base motor", "The arm's power supply", "The arm's control software"], "answer": 0},
  {"question": "What role does the Jacobian play in robotic arm manipulation?", "options": ["Relating joint velocities to end-effector velocity, useful for control", "Storing calibration images", "Managing battery charge", "Designing the arm's PCB"], "answer": 0},
  {"question": "What is motion planning for a robotic arm concerned with?", "options": ["Finding a collision-free path for the arm to move from one configuration to another", "Only the gripper's open/close state", "Only the arm's paint color", "Only Wi-Fi connectivity"], "answer": 0},
  {"question": "Why might different gripper designs be chosen for different tasks?", "options": ["Grip type/force requirements vary depending on the object being manipulated", "All objects require identical grippers", "Grippers have no effect on manipulation", "Gripper choice only affects appearance"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Manipulation & Robotic Arms';

update public.topics set quiz = $q$[
  {"question": "What does state estimation provide for an aerial robot?", "options": ["A real-time estimate of the drone's position, velocity, and orientation", "The drone's total flight time only", "The drone's paint color", "The drone's Wi-Fi password"], "answer": 0},
  {"question": "Why is GPS navigation often insufficient alone for precise aerial control?", "options": ["GPS has limited precision/update rate and can be unreliable indoors or near obstacles", "GPS is always perfectly precise everywhere", "GPS cannot be used on drones at all", "GPS replaces the need for a flight controller"], "answer": 0},
  {"question": "What is the role of ESC/BLDC components in aerial robotics?", "options": ["Driving the brushless motors that spin the propellers for lift/thrust", "Providing GPS positioning", "Processing camera images", "Storing flight logs only"], "answer": 0},
  {"question": "What does 'position control' mean for a drone?", "options": ["Automatically holding or moving to a specific 3D position using sensor feedback", "Manually flying with no automation at all", "Only controlling altitude, never horizontal position", "Only used during landing"], "answer": 0},
  {"question": "Why are PX4 and ArduPilot relevant to aerial robotics specifically?", "options": ["They are widely used open-source flight-control software stacks for drones", "They are PCB manufacturing companies", "They are battery chemistries", "They are camera sensor models"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Aerial Robotics';

update public.topics set quiz = $q$[
  {"question": "What is a CNN (Convolutional Neural Network) particularly well-suited for?", "options": ["Processing image data for tasks like classification and object detection", "Only processing audio data", "Only controlling motor voltage directly", "Only PCB routing"], "answer": 0},
  {"question": "What is the key difference between reinforcement learning and imitation learning?", "options": ["RL learns via trial-and-error rewards; imitation learning learns by mimicking demonstrated behavior", "They are identical techniques", "RL requires no training at all", "Imitation learning cannot be used in robotics"], "answer": 0},
  {"question": "What does 'deep learning' generally refer to?", "options": ["Machine learning using neural networks with many layers", "Any robotics control system regardless of method", "Only classical PID control", "A PCB design technique"], "answer": 0},
  {"question": "What is a practical challenge of using reinforcement learning directly on real robots?", "options": ["Real-world trial-and-error can be slow, costly, or unsafe, so simulation is often used first", "RL always works perfectly on the first attempt with no training", "RL cannot be simulated at all", "It requires no sensors or data"], "answer": 0},
  {"question": "How can AI-based control be combined with classical control (e.g. PID)?", "options": ["AI/ML can handle high-level decisions or perception while classical control handles low-level stabilization", "They can never be used together", "AI always fully replaces PID in every system", "Classical control cannot use any sensor data"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'AI & Robotics';

update public.topics set quiz = $q$[
  {"question": "What is a 'digital twin' in robotics/engineering?", "options": ["A virtual model that mirrors a real system's behavior for testing and analysis", "A second physical robot built as a backup", "A type of battery", "A PCB manufacturing process"], "answer": 0},
  {"question": "What is the difference between SIL and HIL testing?", "options": ["SIL (Software-in-the-Loop) simulates everything in software; HIL (Hardware-in-the-Loop) includes real hardware with simulated inputs", "They are the same thing", "SIL requires real hardware, HIL does not", "Neither involves simulation"], "answer": 0},
  {"question": "What is Isaac Sim primarily used for?", "options": ["A robotics simulation platform, often used for AI/robotics training and testing", "A PCB layout tool", "A battery management system", "A Bluetooth pairing utility"], "answer": 0},
  {"question": "Why might MATLAB/Simulink be used in a digital twin workflow?", "options": ["For modeling, simulating, and analyzing dynamic systems and control algorithms", "Only for writing documentation", "Only for 3D printing", "Only for PCB routing"], "answer": 0},
  {"question": "What is a key benefit of testing control algorithms via a digital twin before deployment?", "options": ["Identifying issues safely and cheaply before risking real hardware", "It guarantees zero bugs will ever occur on real hardware", "It eliminates the need for any real-world testing forever", "It only works for stationary robots"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Digital Twin & Simulation';

update public.topics set quiz = $q$[
  {"question": "What does 'system integration' mean in a robotics project?", "options": ["Combining mechanical, electrical, embedded, and software subsystems into one working whole", "Only writing the final report", "Only choosing a paint color", "Only selecting a battery"], "answer": 0},
  {"question": "Why is communication (e.g. between subsystems/modules) a distinct integration concern?", "options": ["Different subsystems must reliably exchange data/commands without conflicts or data loss", "Communication is irrelevant once mechanical design is finished", "It only matters for aerial robots", "Communication issues never occur in integrated systems"], "answer": 0},
  {"question": "Why is power integration considered separately from other subsystems?", "options": ["All subsystems draw from a shared power budget that must be carefully managed", "Power has no relationship to other subsystems", "Only the motors need power", "Power integration is identical to PCB design"], "answer": 0},
  {"question": "What is a common failure mode when integration is done poorly?", "options": ["Individually working subsystems fail or behave unexpectedly once combined", "Nothing changes when subsystems are combined", "Integration always simplifies debugging", "Integration removes the need for testing"], "answer": 0},
  {"question": "Why involve perception and control teams early when planning system integration?", "options": ["Their interface requirements affect mechanical/electrical design decisions made early on", "Perception and control never interact with other subsystems", "Only the final assembly stage matters", "Early planning has no benefit"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Robotics System Integration';

update public.topics set quiz = $q$[
  {"question": "What is the purpose of unit testing in a robotics software project?", "options": ["Verifying that individual functions/modules behave correctly in isolation", "Testing the entire assembled robot only", "Testing only the battery", "Testing only the PCB"], "answer": 0},
  {"question": "How does simulation testing differ from hardware testing?", "options": ["Simulation testing runs in a virtual environment; hardware testing uses the real physical robot", "They are identical processes", "Simulation testing requires real motors", "Hardware testing requires no robot at all"], "answer": 0},
  {"question": "Why are test plans useful before running experiments/tests?", "options": ["They define what will be tested, how, and what success looks like, avoiding ad hoc testing", "They are unnecessary paperwork with no value", "They replace the need for actual testing", "They are only used for PCB design"], "answer": 0},
  {"question": "What does reproducibility mean in a testing context?", "options": ["Getting consistent results when a test is repeated under the same conditions", "Never running the same test twice", "Only applies to software, never hardware", "Requires a different robot each time"], "answer": 0},
  {"question": "Why is fault detection important in a reliability-focused robotics system?", "options": ["It allows the system to recognize and respond to failures before they cause bigger problems", "Faults never occur in well-built systems", "It only matters for aerial robots", "It has no effect on safety"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Reliability & Testing';

update public.topics set quiz = $q$[
  {"question": "Why is rulebook analysis an important first step in competition robotics?", "options": ["Understanding scoring, constraints, and rules shapes the entire design strategy", "Rules never affect the robot's design", "It's optional and rarely consulted", "Only the electronics team needs to read it"], "answer": 0},
  {"question": "What is the purpose of defining system requirements early in a competition project?", "options": ["Clarifying what the robot must do so design decisions align with competition goals", "To avoid ever changing the design later", "Requirements are irrelevant to competition success", "Only needed for aerial competitions"], "answer": 0},
  {"question": "Why is strategy considered separately from pure engineering in competition robotics?", "options": ["How you use the robot (tactics, scoring approach) matters as much as how well it's built", "Strategy has no impact on competition outcomes", "Only mechanical design determines the winner", "Strategy is decided by judges, not the team"], "answer": 0},
  {"question": "What is the goal of the 'optimization' phase in competition robotics?", "options": ["Refining performance (speed, reliability, scoring efficiency) after the base robot works", "Making the robot as expensive as possible", "Ignoring test results", "Adding unnecessary features"], "answer": 0},
  {"question": "Why does testing matter so much for competition robots specifically?", "options": ["Reliability under real competition conditions/pressure is critical to actually scoring points", "Competitions never involve any testing beforehand", "Only the final design matters, not how it was tested", "Testing is only relevant for research robots"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Competition Robotics';

update public.topics set quiz = $q$[
  {"question": "What is the purpose of a literature review in a research project?", "options": ["Understanding existing work to identify what's already known and where gaps exist", "Writing the final robot code", "Selecting a battery", "Designing a PCB"], "answer": 0},
  {"question": "What is a 'research gap'?", "options": ["An unanswered question or unexplored area identified from reviewing existing work", "A physical gap in the robot's chassis", "A gap in Wi-Fi coverage", "A gap in the PCB traces"], "answer": 0},
  {"question": "Why is careful experiment design important in research?", "options": ["It ensures results are valid, reliable, and actually answer the research question", "Experiments never need planning", "Only data collection matters, not design", "Experiment design only applies to biology research"], "answer": 0},
  {"question": "What is the purpose of technical documentation in R&D work?", "options": ["Recording methods, results, and reasoning so work can be understood, reproduced, or built upon", "Only for legal compliance with no other use", "Replacing the need for actual experiments", "Only required for competition robotics"], "answer": 0},
  {"question": "Why is results/analysis considered a distinct step from data collection?", "options": ["Raw data must be interpreted and analyzed to draw meaningful conclusions", "Collected data automatically interprets itself", "Analysis is optional once data exists", "They are the same step"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Research & Development';

update public.projects set quiz = $q$[
  {"question": "What is the Level 04 Capstone meant to demonstrate?", "options": ["Complete system integration and mastery across the Stage 4 curriculum", "Only a basic LED circuit", "Only a PCB schematic with no working robot", "Only a written essay with no build"], "answer": 0},
  {"question": "Which of these is a valid focus option for this capstone?", "options": ["Autonomous systems, vision/manipulation, aerial robotics, or AI robotics", "Only merchandise design", "Only Stage 1 electronics basics", "Only breadboard prototyping"], "answer": 0},
  {"question": "Why does this capstone emphasize 'complete system integration'?", "options": ["A professional-level project must combine mechanical, electrical, software, and control subsystems reliably", "Integration is unnecessary at this advanced level", "Only one subsystem needs to function", "Integration was already covered fully in Stage 1"], "answer": 0},
  {"question": "Why might a team choose simulation-based validation before final hardware integration?", "options": ["To catch design/control issues early and safely, especially for complex or risky subsystems", "Simulation is required by competition rules only", "Simulation replaces the need for any real hardware ever", "Simulation is only relevant for PCB design"], "answer": 0},
  {"question": "What distinguishes this capstone from earlier stage projects?", "options": ["It expects professional-level complexity, research rigor, and full system integration", "It is simpler than the Stage 1 projects", "It requires no testing or documentation", "It only tests a single isolated skill"], "answer": 0}
]$q$::jsonb
where stage_id = (select id from public.stages where number = 4) and title = 'Level 04 Capstone';
