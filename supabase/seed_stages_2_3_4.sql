-- =========================================================
-- Seed: Stages 2-4 structure (stages, sessions, topics, projects)
-- from "Robodarshan_Stage_2_3_4_Study_Materials.pdf", plus
-- aligning all 4 stage titles/themes with the official
-- requirements doc, plus setting pdf_url on Stage 1's existing
-- items to match the new PDF-based content model.
--
-- Run after migration 007_pdf_materials_and_quiz_attempts.sql.
-- Safe to re-run: guards against duplicate inserts by title/stage.
--
-- pdf_url convention: /study-materials/stage-<N>/<kebab-title>.pdf
-- Drop matching PDF files into study-materials/stage-<N>/ locally
-- (see the file list in the assistant's message for exact names).
-- =========================================================

-- ---------------------------------------------------------
-- Align stage titles/themes with the official spec, and set
-- pdf_url on Stage 1's existing topics/projects.
-- ---------------------------------------------------------
update public.stages set title = 'Robotics Beginner', theme = 'BUILD' where number = 1;

update public.topics set pdf_url = '/study-materials/stage-1/introduction-to-robotics.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Introduction to Robotics';
update public.topics set pdf_url = '/study-materials/stage-1/basic-electronics.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Basic Electronics';
update public.topics set pdf_url = '/study-materials/stage-1/tools-and-workshop-skills.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Tools & Workshop Skills';
update public.topics set pdf_url = '/study-materials/stage-1/breadboard-and-circuit-building.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Breadboard & Circuit Building';
update public.topics set pdf_url = '/study-materials/stage-1/arduino-fundamentals.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Arduino Fundamentals';
update public.topics set pdf_url = '/study-materials/stage-1/esp32-fundamentals.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'ESP32 Fundamentals';
update public.topics set pdf_url = '/study-materials/stage-1/tinkercad.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Tinkercad';
update public.topics set pdf_url = '/study-materials/stage-1/digital-analog-and-pwm.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Digital, Analog and PWM';
update public.topics set pdf_url = '/study-materials/stage-1/sensors.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Sensors';
update public.topics set pdf_url = '/study-materials/stage-1/motors-and-motor-drivers.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Motors & motor drivers';

update public.projects set pdf_url = '/study-materials/stage-1/bluetooth-controlled-car.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Bluetooth Controlled Car';
update public.projects set pdf_url = '/study-materials/stage-1/obstacle-avoiding-car.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Obstacle Avoiding Car';

-- ---------------------------------------------------------
-- Stage 2 -- Robotics Intermediate | CONTROL
-- ---------------------------------------------------------
insert into public.stages (number, title, theme)
values (2, 'Robotics Intermediate', 'CONTROL')
on conflict (number) do update set title = excluded.title, theme = excluded.theme;

insert into public.sessions (stage_id, title, content, xp_value)
select (select id from public.stages where number = 2), 'Session Attendance',
  'Mark your attendance for the Stage 2 kickoff session. Your instructor will verify attendance and approve this from the admin side.', 50
where not exists (select 1 from public.sessions where stage_id = (select id from public.stages where number = 2) and title = 'Session Attendance');

insert into public.topics (stage_id, title, learning_objectives, pdf_url, xp_value, status)
select (select id from public.stages where number = 2), t.title, t.objectives, t.pdf_url, 10, 'published'
from (values
  ('ESP32 Communication & IoT', 'Serial, UART, I2C, SPI, Wi-Fi, Web server, Bluetooth/BLE, ESP32 robot control', '/study-materials/stage-2/esp32-communication-and-iot.pdf'),
  ('Intermediate Robotics Programming', 'Arrays, structures, modular programming, millis(), interrupts, state machines', '/study-materials/stage-2/intermediate-robotics-programming.pdf'),
  ('Intermediate Sensors', 'IR array, encoders, IMU, calibration, RPM, introduction to odometry', '/study-materials/stage-2/intermediate-sensors.pdf'),
  ('Robot Mechanics', 'Differential drive, wheel selection, torque, RPM, gear ratio, friction/traction, centre of gravity', '/study-materials/stage-2/robot-mechanics.pdf'),
  ('Motor Control', 'Open-loop control, closed-loop control, encoder feedback, speed matching, introduction to position control', '/study-materials/stage-2/motor-control.pdf'),
  ('PID Control', 'Error and setpoint, P/I/D, PID equation, tuning, overshoot, oscillation, stability, practical PID', '/study-materials/stage-2/pid-control.pdf'),
  ('Line Follower', 'IR array, calibration, line detection, basic line following, motor control', '/study-materials/stage-2/line-follower.pdf'),
  ('PID Line Follower', 'Error calculation, PID, motor-speed correction, tuning', '/study-materials/stage-2/pid-line-follower.pdf'),
  ('Maze Solver', 'Junction detection, decision making, dead ends, path recording, shortest-path introduction', '/study-materials/stage-2/maze-solver.pdf'),
  ('PCB Design', 'Schematic, layout/routing, DRC, Gerber, KiCad, EasyEDA', '/study-materials/stage-2/pcb-design.pdf'),
  ('Power Systems', 'Power budget, motor current, battery selection, voltage regulators, buck converters, BMS', '/study-materials/stage-2/power-systems.pdf'),
  ('Robot Debugging', 'Sensor calibration, motor matching, encoder errors, communication issues, power issues', '/study-materials/stage-2/robot-debugging.pdf')
) as t(title, objectives, pdf_url)
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 2) and title = t.title
);

insert into public.projects (stage_id, title, requirements, instructions, pdf_url, xp_value)
select (select id from public.stages where number = 2),
  'Stage 02 Challenge',
  'Line-following robot chassis with IR array, plus a maze layout for testing.',
  'Build a PID-tuned line follower, then extend it into a maze solver. Optional: add encoder-based speed control. Implement on ESP32.',
  '/study-materials/stage-2/stage-02-challenge.pdf',
  100
where not exists (select 1 from public.projects where stage_id = (select id from public.stages where number = 2) and title = 'Stage 02 Challenge');

-- ---------------------------------------------------------
-- Stage 3 -- Advanced Robotics | AUTONOMY
-- ---------------------------------------------------------
insert into public.stages (number, title, theme)
values (3, 'Advanced Robotics', 'AUTONOMY')
on conflict (number) do update set title = excluded.title, theme = excluded.theme;

insert into public.sessions (stage_id, title, content, xp_value)
select (select id from public.stages where number = 3), 'Session Attendance',
  'Mark your attendance for the Stage 3 kickoff session. Your instructor will verify attendance and approve this from the admin side.', 50
where not exists (select 1 from public.sessions where stage_id = (select id from public.stages where number = 3) and title = 'Session Attendance');

insert into public.topics (stage_id, title, learning_objectives, pdf_url, xp_value, status)
select (select id from public.stages where number = 3), t.title, t.objectives, t.pdf_url, 10, 'published'
from (values
  ('Advanced Embedded Systems', 'Advanced ESP32, interrupts/timers, PWM/ADC, FreeRTOS introduction, multitasking', '/study-materials/stage-3/advanced-embedded-systems.pdf'),
  ('Advanced Sensors & Sensor Fusion', 'IMU, encoder, magnetometer, barometer, GPS, LiDAR, sensor fusion, Kalman filter introduction', '/study-materials/stage-3/advanced-sensors-and-sensor-fusion.pdf'),
  ('Robot Kinematics', 'Coordinate frames, rotation/translation, transformation matrices, differential-drive kinematics, forward/inverse kinematics', '/study-materials/stage-3/robot-kinematics.pdf'),
  ('Advanced Control', 'Advanced PID, feedforward, cascaded control, state-space introduction, stability', '/study-materials/stage-3/advanced-control.pdf'),
  ('Computer Vision', 'Images/pixels, RGB/grayscale, thresholding, filtering/edges, contours, OpenCV, object detection, camera calibration', '/study-materials/stage-3/computer-vision.pdf'),
  ('ROS 2 Fundamentals', 'ROS 2 concepts, nodes, topics, publishers/subscribers, services, actions, messages, parameters, launch files', '/study-materials/stage-3/ros-2-fundamentals.pdf'),
  ('Robot Simulation', 'Gazebo, RViz, URDF, Xacro, ROS 2 + Gazebo', '/study-materials/stage-3/robot-simulation.pdf'),
  ('Localization', 'Odometry, IMU/GPS, AMCL, Kalman filter introduction', '/study-materials/stage-3/localization.pdf'),
  ('Mapping & SLAM', 'Mapping, LiDAR, SLAM, 2D SLAM, map building', '/study-materials/stage-3/mapping-and-slam.pdf'),
  ('Path Planning & Navigation', 'BFS, DFS, Dijkstra, A*, global planning, local planning, obstacle avoidance', '/study-materials/stage-3/path-planning-and-navigation.pdf'),
  ('Autonomous Navigation', 'Autonomous navigation combining localization, mapping, and path planning', '/study-materials/stage-3/autonomous-navigation.pdf'),
  ('AI/ML for Robotics', 'Machine learning for robotics, neural networks, classification, object detection, inference, AI + robotics', '/study-materials/stage-3/ai-ml-for-robotics.pdf'),
  ('Introduction to Drones', 'Multirotor, BLDC, ESC, propellers, flight controller, IMU, barometer, GPS, PX4, ArduPilot, simulation-first workflow', '/study-materials/stage-3/introduction-to-drones.pdf')
) as t(title, objectives, pdf_url)
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 3) and title = t.title
);

insert into public.projects (stage_id, title, requirements, instructions, pdf_url, xp_value)
select (select id from public.stages where number = 3), p.title, p.requirements, p.instructions, p.pdf_url, 100
from (values
  ('ROS 2 Autonomous Robot', 'ROS 2-capable computer (e.g. Raspberry Pi), robot base with sensors, Gazebo/RViz for simulation.', 'Build and run an autonomous robot using ROS 2 nodes for sensing, localization, and navigation.', '/study-materials/stage-3/ros-2-autonomous-robot.pdf'),
  ('Vision-Based Robot', 'Camera module, OpenCV-capable computer, robot base.', 'Build a robot that uses computer vision (e.g. object detection or line/color tracking) to make navigation decisions.', '/study-materials/stage-3/vision-based-robot.pdf'),
  ('Stage 03 Capstone', 'Depends on chosen option: autonomous rover, vision-based robot, autonomous drone, or robotic arm + vision.', 'Choose one capstone build combining Stage 3 skills end to end: autonomous rover, vision-based robot, autonomous drone, or robotic arm + vision.', '/study-materials/stage-3/stage-03-capstone.pdf')
) as p(title, requirements, instructions, pdf_url)
where not exists (
  select 1 from public.projects where stage_id = (select id from public.stages where number = 3) and title = p.title
);

-- ---------------------------------------------------------
-- Stage 4 -- Professional & Research Robotics | PROFESSIONAL / R&D
-- ---------------------------------------------------------
insert into public.stages (number, title, theme)
values (4, 'Professional & Research Robotics', 'PROFESSIONAL / R&D')
on conflict (number) do update set title = excluded.title, theme = excluded.theme;

insert into public.sessions (stage_id, title, content, xp_value)
select (select id from public.stages where number = 4), 'Session Attendance',
  'Mark your attendance for the Stage 4 kickoff session. Your instructor will verify attendance and approve this from the admin side.', 50
where not exists (select 1 from public.sessions where stage_id = (select id from public.stages where number = 4) and title = 'Session Attendance');

insert into public.topics (stage_id, title, learning_objectives, pdf_url, xp_value, status)
select (select id from public.stages where number = 4), t.title, t.objectives, t.pdf_url, 10, 'published'
from (values
  ('Advanced Robotics Software', 'C++ for robotics, Python, Linux, Git/GitHub, Docker, software architecture', '/study-materials/stage-4/advanced-robotics-software.pdf'),
  ('Advanced ROS 2', 'Architecture, TF/TF2, URDF/Xacro, lifecycle nodes, ROS 2 Control, custom messages, parameters, launch', '/study-materials/stage-4/advanced-ros-2.pdf'),
  ('Advanced Robot Kinematics', 'DH parameters, manipulator kinematics, Jacobian, singularities, workspace, trajectory generation', '/study-materials/stage-4/advanced-robot-kinematics.pdf'),
  ('Advanced Control', 'State-space, feedback linearization, LQR, MPC, adaptive control, robust control', '/study-materials/stage-4/advanced-control.pdf'),
  ('Advanced Perception', '3D vision, depth cameras, point clouds, LiDAR processing, detection/tracking, 3D reconstruction', '/study-materials/stage-4/advanced-perception.pdf'),
  ('Advanced Localization & SLAM', 'EKF, UKF, visual odometry, LiDAR SLAM, visual SLAM, multi-sensor fusion', '/study-materials/stage-4/advanced-localization-and-slam.pdf'),
  ('Advanced Path Planning', 'A*, D*, RRT, RRT*, trajectory planning, dynamic obstacle avoidance', '/study-materials/stage-4/advanced-path-planning.pdf'),
  ('Manipulation & Robotic Arms', 'Architecture, DOF, kinematics, Jacobian, end effectors, grippers, motion planning', '/study-materials/stage-4/manipulation-and-robotic-arms.pdf'),
  ('Aerial Robotics', 'Multirotor dynamics, flight controllers, ESC/BLDC, state estimation, position control, GPS navigation, PX4, ArduPilot', '/study-materials/stage-4/aerial-robotics.pdf'),
  ('AI & Robotics', 'Deep learning, CNN, object detection, reinforcement learning, imitation learning, AI-based control', '/study-materials/stage-4/ai-and-robotics.pdf'),
  ('Digital Twin & Simulation', 'Gazebo, Isaac Sim, MATLAB/Simulink, SIL, HIL', '/study-materials/stage-4/digital-twin-and-simulation.pdf'),
  ('Robotics System Integration', 'Mechanical, electronics, embedded, software, control, perception, communication, power integration', '/study-materials/stage-4/robotics-system-integration.pdf'),
  ('Reliability & Testing', 'Unit testing, simulation testing, hardware testing, fault detection, safety, test plans, reproducibility', '/study-materials/stage-4/reliability-and-testing.pdf'),
  ('Competition Robotics', 'Rulebook analysis, strategy, system requirements, mechanical design, electronics, autonomy, testing, optimization', '/study-materials/stage-4/competition-robotics.pdf'),
  ('Research & Development', 'Research papers, literature review, research gaps, experiment design, data collection, results/analysis, technical documentation', '/study-materials/stage-4/research-and-development.pdf')
) as t(title, objectives, pdf_url)
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 4) and title = t.title
);

insert into public.projects (stage_id, title, requirements, instructions, pdf_url, xp_value)
select (select id from public.stages where number = 4),
  'Level 04 Capstone',
  'Depends on chosen focus: autonomous systems, vision/manipulation, aerial robotics, or AI robotics.',
  'Design, build, and integrate a complete robotics system demonstrating mastery across the Stage 4 curriculum -- autonomous systems, vision/manipulation, aerial robotics, or AI robotics, with full system integration.',
  '/study-materials/stage-4/level-04-capstone.pdf',
  100
where not exists (select 1 from public.projects where stage_id = (select id from public.stages where number = 4) and title = 'Level 04 Capstone');
