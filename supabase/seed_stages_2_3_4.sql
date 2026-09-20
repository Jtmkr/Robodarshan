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
-- pdf_url convention: /study-materials/stage-<N>/<number>.pdf for lessons
-- (in curriculum order) and /study-materials/stage-<N>/project<N>.pdf
-- for projects. Drop matching PDF files into study-materials/stage-<N>/.
-- =========================================================

-- ---------------------------------------------------------
-- Align stage titles/themes with the official spec, and set
-- pdf_url on Stage 1's existing topics/projects.
-- ---------------------------------------------------------
update public.stages set title = 'Robotics Beginner', theme = 'BUILD' where number = 1;

update public.topics set pdf_url = '/study-materials/stage-1/1.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Introduction to Robotics';
update public.topics set pdf_url = '/study-materials/stage-1/2.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Basic Electronics';
update public.topics set pdf_url = '/study-materials/stage-1/3.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Tools & Workshop Skills';
update public.topics set pdf_url = '/study-materials/stage-1/4.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Breadboard & Circuit Building';
update public.topics set pdf_url = '/study-materials/stage-1/5.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Arduino Fundamentals';
update public.topics set pdf_url = '/study-materials/stage-1/6.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'ESP32 Fundamentals';
update public.topics set pdf_url = '/study-materials/stage-1/7.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Tinkercad';
update public.topics set pdf_url = '/study-materials/stage-1/8.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Digital, Analog and PWM';
update public.topics set pdf_url = '/study-materials/stage-1/9.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Sensors';
update public.topics set pdf_url = '/study-materials/stage-1/10.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Motors & motor drivers';

update public.projects set pdf_url = '/study-materials/stage-1/project1.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Bluetooth Controlled Car';
update public.projects set pdf_url = '/study-materials/stage-1/project2.pdf' where stage_id = (select id from public.stages where number = 1) and title = 'Obstacle Avoiding Car';

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
  ('ESP32 Communication & IoT', 'Serial, UART, I2C, SPI, Wi-Fi, Web server, Bluetooth/BLE, ESP32 robot control', '/study-materials/stage-2/1.pdf'),
  ('Intermediate Robotics Programming', 'Arrays, structures, modular programming, millis(), interrupts, state machines', '/study-materials/stage-2/2.pdf'),
  ('Intermediate Sensors', 'IR array, encoders, IMU, calibration, RPM, introduction to odometry', '/study-materials/stage-2/3.pdf'),
  ('Robot Mechanics', 'Differential drive, wheel selection, torque, RPM, gear ratio, friction/traction, centre of gravity', '/study-materials/stage-2/4.pdf'),
  ('Motor Control', 'Open-loop control, closed-loop control, encoder feedback, speed matching, introduction to position control', '/study-materials/stage-2/5.pdf'),
  ('PID Control', 'Error and setpoint, P/I/D, PID equation, tuning, overshoot, oscillation, stability, practical PID', '/study-materials/stage-2/6.pdf'),
  ('Line Follower', 'IR array, calibration, line detection, basic line following, motor control', '/study-materials/stage-2/7.pdf'),
  ('PID Line Follower', 'Error calculation, PID, motor-speed correction, tuning', '/study-materials/stage-2/8.pdf'),
  ('Maze Solver', 'Junction detection, decision making, dead ends, path recording, shortest-path introduction', '/study-materials/stage-2/9.pdf'),
  ('PCB Design', 'Schematic, layout/routing, DRC, Gerber, KiCad, EasyEDA', '/study-materials/stage-2/10.pdf'),
  ('Power Systems', 'Power budget, motor current, battery selection, voltage regulators, buck converters, BMS', '/study-materials/stage-2/11.pdf'),
  ('Robot Debugging', 'Sensor calibration, motor matching, encoder errors, communication issues, power issues', '/study-materials/stage-2/12.pdf')
) as t(title, objectives, pdf_url)
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 2) and title = t.title
);

insert into public.projects (stage_id, title, requirements, instructions, pdf_url, xp_value)
select (select id from public.stages where number = 2),
  'Stage 02 Challenge',
  'Line-following robot chassis with IR array, plus a maze layout for testing.',
  'Build a PID-tuned line follower, then extend it into a maze solver. Optional: add encoder-based speed control. Implement on ESP32.',
  '/study-materials/stage-2/project1.pdf',
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
  ('Advanced Embedded Systems', 'Advanced ESP32, interrupts/timers, PWM/ADC, FreeRTOS introduction, multitasking', '/study-materials/stage-3/1.pdf'),
  ('Advanced Sensors & Sensor Fusion', 'IMU, encoder, magnetometer, barometer, GPS, LiDAR, sensor fusion, Kalman filter introduction', '/study-materials/stage-3/2.pdf'),
  ('Robot Kinematics', 'Coordinate frames, rotation/translation, transformation matrices, differential-drive kinematics, forward/inverse kinematics', '/study-materials/stage-3/3.pdf'),
  ('Advanced Control', 'Advanced PID, feedforward, cascaded control, state-space introduction, stability', '/study-materials/stage-3/4.pdf'),
  ('Computer Vision', 'Images/pixels, RGB/grayscale, thresholding, filtering/edges, contours, OpenCV, object detection, camera calibration', '/study-materials/stage-3/5.pdf'),
  ('ROS 2 Fundamentals', 'ROS 2 concepts, nodes, topics, publishers/subscribers, services, actions, messages, parameters, launch files', '/study-materials/stage-3/6.pdf'),
  ('Robot Simulation', 'Gazebo, RViz, URDF, Xacro, ROS 2 + Gazebo', '/study-materials/stage-3/7.pdf'),
  ('Localization', 'Odometry, IMU/GPS, AMCL, Kalman filter introduction', '/study-materials/stage-3/8.pdf'),
  ('Mapping & SLAM', 'Mapping, LiDAR, SLAM, 2D SLAM, map building', '/study-materials/stage-3/9.pdf'),
  ('Path Planning & Navigation', 'BFS, DFS, Dijkstra, A*, global planning, local planning, obstacle avoidance', '/study-materials/stage-3/10.pdf'),
  ('Autonomous Navigation', 'Autonomous navigation combining localization, mapping, and path planning', '/study-materials/stage-3/11.pdf'),
  ('AI/ML for Robotics', 'Machine learning for robotics, neural networks, classification, object detection, inference, AI + robotics', '/study-materials/stage-3/12.pdf'),
  ('Introduction to Drones', 'Multirotor, BLDC, ESC, propellers, flight controller, IMU, barometer, GPS, PX4, ArduPilot, simulation-first workflow', '/study-materials/stage-3/13.pdf')
) as t(title, objectives, pdf_url)
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 3) and title = t.title
);

insert into public.projects (stage_id, title, requirements, instructions, pdf_url, xp_value)
select (select id from public.stages where number = 3), p.title, p.requirements, p.instructions, p.pdf_url, 100
from (values
  ('ROS 2 Autonomous Robot', 'ROS 2-capable computer (e.g. Raspberry Pi), robot base with sensors, Gazebo/RViz for simulation.', 'Build and run an autonomous robot using ROS 2 nodes for sensing, localization, and navigation.', '/study-materials/stage-3/project1.pdf'),
  ('Vision-Based Robot', 'Camera module, OpenCV-capable computer, robot base.', 'Build a robot that uses computer vision (e.g. object detection or line/color tracking) to make navigation decisions.', '/study-materials/stage-3/project2.pdf'),
  ('Stage 03 Capstone', 'Depends on chosen option: autonomous rover, vision-based robot, autonomous drone, or robotic arm + vision.', 'Choose one capstone build combining Stage 3 skills end to end: autonomous rover, vision-based robot, autonomous drone, or robotic arm + vision.', '/study-materials/stage-3/project3.pdf')
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
  ('Advanced Robotics Software', 'C++ for robotics, Python, Linux, Git/GitHub, Docker, software architecture', '/study-materials/stage-4/1.pdf'),
  ('Advanced ROS 2', 'Architecture, TF/TF2, URDF/Xacro, lifecycle nodes, ROS 2 Control, custom messages, parameters, launch', '/study-materials/stage-4/2.pdf'),
  ('Advanced Robot Kinematics', 'DH parameters, manipulator kinematics, Jacobian, singularities, workspace, trajectory generation', '/study-materials/stage-4/3.pdf'),
  ('Advanced Control', 'State-space, feedback linearization, LQR, MPC, adaptive control, robust control', '/study-materials/stage-4/4.pdf'),
  ('Advanced Perception', '3D vision, depth cameras, point clouds, LiDAR processing, detection/tracking, 3D reconstruction', '/study-materials/stage-4/5.pdf'),
  ('Advanced Localization & SLAM', 'EKF, UKF, visual odometry, LiDAR SLAM, visual SLAM, multi-sensor fusion', '/study-materials/stage-4/6.pdf'),
  ('Advanced Path Planning', 'A*, D*, RRT, RRT*, trajectory planning, dynamic obstacle avoidance', '/study-materials/stage-4/7.pdf'),
  ('Manipulation & Robotic Arms', 'Architecture, DOF, kinematics, Jacobian, end effectors, grippers, motion planning', '/study-materials/stage-4/8.pdf'),
  ('Aerial Robotics', 'Multirotor dynamics, flight controllers, ESC/BLDC, state estimation, position control, GPS navigation, PX4, ArduPilot', '/study-materials/stage-4/9.pdf'),
  ('AI & Robotics', 'Deep learning, CNN, object detection, reinforcement learning, imitation learning, AI-based control', '/study-materials/stage-4/10.pdf'),
  ('Digital Twin & Simulation', 'Gazebo, Isaac Sim, MATLAB/Simulink, SIL, HIL', '/study-materials/stage-4/11.pdf'),
  ('Robotics System Integration', 'Mechanical, electronics, embedded, software, control, perception, communication, power integration', '/study-materials/stage-4/12.pdf'),
  ('Reliability & Testing', 'Unit testing, simulation testing, hardware testing, fault detection, safety, test plans, reproducibility', '/study-materials/stage-4/13.pdf'),
  ('Competition Robotics', 'Rulebook analysis, strategy, system requirements, mechanical design, electronics, autonomy, testing, optimization', '/study-materials/stage-4/14.pdf'),
  ('Research & Development', 'Research papers, literature review, research gaps, experiment design, data collection, results/analysis, technical documentation', '/study-materials/stage-4/15.pdf')
) as t(title, objectives, pdf_url)
where not exists (
  select 1 from public.topics where stage_id = (select id from public.stages where number = 4) and title = t.title
);

insert into public.projects (stage_id, title, requirements, instructions, pdf_url, xp_value)
select (select id from public.stages where number = 4),
  'Level 04 Capstone',
  'Depends on chosen focus: autonomous systems, vision/manipulation, aerial robotics, or AI robotics.',
  'Design, build, and integrate a complete robotics system demonstrating mastery across the Stage 4 curriculum -- autonomous systems, vision/manipulation, aerial robotics, or AI robotics, with full system integration.',
  '/study-materials/stage-4/project1.pdf',
  100
where not exists (select 1 from public.projects where stage_id = (select id from public.stages where number = 4) and title = 'Level 04 Capstone');

-- ---------------------------------------------------------
-- Explicit curriculum order for Stages 2-4 (see migration
-- 009_explicit_item_ordering.sql for why this matters -- rows
-- inserted in one script share the same created_at, so ordering
-- by created_at alone is not reliable).
-- ---------------------------------------------------------
update public.topics set order_index = 1 where stage_id = (select id from public.stages where number = 2) and title = 'ESP32 Communication & IoT';
update public.topics set order_index = 2 where stage_id = (select id from public.stages where number = 2) and title = 'Intermediate Robotics Programming';
update public.topics set order_index = 3 where stage_id = (select id from public.stages where number = 2) and title = 'Intermediate Sensors';
update public.topics set order_index = 4 where stage_id = (select id from public.stages where number = 2) and title = 'Robot Mechanics';
update public.topics set order_index = 5 where stage_id = (select id from public.stages where number = 2) and title = 'Motor Control';
update public.topics set order_index = 6 where stage_id = (select id from public.stages where number = 2) and title = 'PID Control';
update public.topics set order_index = 7 where stage_id = (select id from public.stages where number = 2) and title = 'Line Follower';
update public.topics set order_index = 8 where stage_id = (select id from public.stages where number = 2) and title = 'PID Line Follower';
update public.topics set order_index = 9 where stage_id = (select id from public.stages where number = 2) and title = 'Maze Solver';
update public.topics set order_index = 10 where stage_id = (select id from public.stages where number = 2) and title = 'PCB Design';
update public.topics set order_index = 11 where stage_id = (select id from public.stages where number = 2) and title = 'Power Systems';
update public.topics set order_index = 12 where stage_id = (select id from public.stages where number = 2) and title = 'Robot Debugging';
update public.projects set order_index = 1 where stage_id = (select id from public.stages where number = 2) and title = 'Stage 02 Challenge';

update public.topics set order_index = 1 where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Embedded Systems';
update public.topics set order_index = 2 where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Sensors & Sensor Fusion';
update public.topics set order_index = 3 where stage_id = (select id from public.stages where number = 3) and title = 'Robot Kinematics';
update public.topics set order_index = 4 where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Control';
update public.topics set order_index = 5 where stage_id = (select id from public.stages where number = 3) and title = 'Computer Vision';
update public.topics set order_index = 6 where stage_id = (select id from public.stages where number = 3) and title = 'ROS 2 Fundamentals';
update public.topics set order_index = 7 where stage_id = (select id from public.stages where number = 3) and title = 'Robot Simulation';
update public.topics set order_index = 8 where stage_id = (select id from public.stages where number = 3) and title = 'Localization';
update public.topics set order_index = 9 where stage_id = (select id from public.stages where number = 3) and title = 'Mapping & SLAM';
update public.topics set order_index = 10 where stage_id = (select id from public.stages where number = 3) and title = 'Path Planning & Navigation';
update public.topics set order_index = 11 where stage_id = (select id from public.stages where number = 3) and title = 'Autonomous Navigation';
update public.topics set order_index = 12 where stage_id = (select id from public.stages where number = 3) and title = 'AI/ML for Robotics';
update public.topics set order_index = 13 where stage_id = (select id from public.stages where number = 3) and title = 'Introduction to Drones';
update public.projects set order_index = 1 where stage_id = (select id from public.stages where number = 3) and title = 'ROS 2 Autonomous Robot';
update public.projects set order_index = 2 where stage_id = (select id from public.stages where number = 3) and title = 'Vision-Based Robot';
update public.projects set order_index = 3 where stage_id = (select id from public.stages where number = 3) and title = 'Stage 03 Capstone';

update public.topics set order_index = 1 where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Robotics Software';
update public.topics set order_index = 2 where stage_id = (select id from public.stages where number = 4) and title = 'Advanced ROS 2';
update public.topics set order_index = 3 where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Robot Kinematics';
update public.topics set order_index = 4 where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Control';
update public.topics set order_index = 5 where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Perception';
update public.topics set order_index = 6 where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Localization & SLAM';
update public.topics set order_index = 7 where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Path Planning';
update public.topics set order_index = 8 where stage_id = (select id from public.stages where number = 4) and title = 'Manipulation & Robotic Arms';
update public.topics set order_index = 9 where stage_id = (select id from public.stages where number = 4) and title = 'Aerial Robotics';
update public.topics set order_index = 10 where stage_id = (select id from public.stages where number = 4) and title = 'AI & Robotics';
update public.topics set order_index = 11 where stage_id = (select id from public.stages where number = 4) and title = 'Digital Twin & Simulation';
update public.topics set order_index = 12 where stage_id = (select id from public.stages where number = 4) and title = 'Robotics System Integration';
update public.topics set order_index = 13 where stage_id = (select id from public.stages where number = 4) and title = 'Reliability & Testing';
update public.topics set order_index = 14 where stage_id = (select id from public.stages where number = 4) and title = 'Competition Robotics';
update public.topics set order_index = 15 where stage_id = (select id from public.stages where number = 4) and title = 'Research & Development';
update public.projects set order_index = 1 where stage_id = (select id from public.stages where number = 4) and title = 'Level 04 Capstone';
