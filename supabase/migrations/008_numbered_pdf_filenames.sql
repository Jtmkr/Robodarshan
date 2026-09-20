-- =========================================================
-- Migration: rename pdf_url values from kebab-case titles to a
-- simple numbered scheme: lessons (topics) are 1.pdf, 2.pdf, ...
-- in the same order they were seeded; projects are project1.pdf,
-- project2.pdf, ... Folder layout is unchanged
-- (study-materials/stage-<N>/).
--
-- Drop your PDFs into each stage folder using these exact names.
-- =========================================================

-- ===================== STAGE 1 =====================
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

-- ===================== STAGE 2 =====================
update public.topics set pdf_url = '/study-materials/stage-2/1.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'ESP32 Communication & IoT';
update public.topics set pdf_url = '/study-materials/stage-2/2.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Intermediate Robotics Programming';
update public.topics set pdf_url = '/study-materials/stage-2/3.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Intermediate Sensors';
update public.topics set pdf_url = '/study-materials/stage-2/4.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Robot Mechanics';
update public.topics set pdf_url = '/study-materials/stage-2/5.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Motor Control';
update public.topics set pdf_url = '/study-materials/stage-2/6.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'PID Control';
update public.topics set pdf_url = '/study-materials/stage-2/7.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Line Follower';
update public.topics set pdf_url = '/study-materials/stage-2/8.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'PID Line Follower';
update public.topics set pdf_url = '/study-materials/stage-2/9.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Maze Solver';
update public.topics set pdf_url = '/study-materials/stage-2/10.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'PCB Design';
update public.topics set pdf_url = '/study-materials/stage-2/11.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Power Systems';
update public.topics set pdf_url = '/study-materials/stage-2/12.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Robot Debugging';

update public.projects set pdf_url = '/study-materials/stage-2/project1.pdf' where stage_id = (select id from public.stages where number = 2) and title = 'Stage 02 Challenge';

-- ===================== STAGE 3 =====================
update public.topics set pdf_url = '/study-materials/stage-3/1.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Embedded Systems';
update public.topics set pdf_url = '/study-materials/stage-3/2.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Sensors & Sensor Fusion';
update public.topics set pdf_url = '/study-materials/stage-3/3.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Robot Kinematics';
update public.topics set pdf_url = '/study-materials/stage-3/4.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Advanced Control';
update public.topics set pdf_url = '/study-materials/stage-3/5.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Computer Vision';
update public.topics set pdf_url = '/study-materials/stage-3/6.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'ROS 2 Fundamentals';
update public.topics set pdf_url = '/study-materials/stage-3/7.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Robot Simulation';
update public.topics set pdf_url = '/study-materials/stage-3/8.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Localization';
update public.topics set pdf_url = '/study-materials/stage-3/9.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Mapping & SLAM';
update public.topics set pdf_url = '/study-materials/stage-3/10.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Path Planning & Navigation';
update public.topics set pdf_url = '/study-materials/stage-3/11.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Autonomous Navigation';
update public.topics set pdf_url = '/study-materials/stage-3/12.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'AI/ML for Robotics';
update public.topics set pdf_url = '/study-materials/stage-3/13.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Introduction to Drones';

update public.projects set pdf_url = '/study-materials/stage-3/project1.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'ROS 2 Autonomous Robot';
update public.projects set pdf_url = '/study-materials/stage-3/project2.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Vision-Based Robot';
update public.projects set pdf_url = '/study-materials/stage-3/project3.pdf' where stage_id = (select id from public.stages where number = 3) and title = 'Stage 03 Capstone';

-- ===================== STAGE 4 =====================
update public.topics set pdf_url = '/study-materials/stage-4/1.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Robotics Software';
update public.topics set pdf_url = '/study-materials/stage-4/2.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Advanced ROS 2';
update public.topics set pdf_url = '/study-materials/stage-4/3.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Robot Kinematics';
update public.topics set pdf_url = '/study-materials/stage-4/4.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Control';
update public.topics set pdf_url = '/study-materials/stage-4/5.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Perception';
update public.topics set pdf_url = '/study-materials/stage-4/6.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Localization & SLAM';
update public.topics set pdf_url = '/study-materials/stage-4/7.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Advanced Path Planning';
update public.topics set pdf_url = '/study-materials/stage-4/8.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Manipulation & Robotic Arms';
update public.topics set pdf_url = '/study-materials/stage-4/9.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Aerial Robotics';
update public.topics set pdf_url = '/study-materials/stage-4/10.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'AI & Robotics';
update public.topics set pdf_url = '/study-materials/stage-4/11.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Digital Twin & Simulation';
update public.topics set pdf_url = '/study-materials/stage-4/12.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Robotics System Integration';
update public.topics set pdf_url = '/study-materials/stage-4/13.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Reliability & Testing';
update public.topics set pdf_url = '/study-materials/stage-4/14.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Competition Robotics';
update public.topics set pdf_url = '/study-materials/stage-4/15.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Research & Development';

update public.projects set pdf_url = '/study-materials/stage-4/project1.pdf' where stage_id = (select id from public.stages where number = 4) and title = 'Level 04 Capstone';
