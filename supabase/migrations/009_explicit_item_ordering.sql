-- =========================================================
-- Migration: add an explicit order_index to topics/projects and
-- backfill it to match the curriculum order (the same order the
-- 1.pdf/2.pdf/.../projectN.pdf numbering assumes).
--
-- Root cause of "lessons/projects not in correct order": all rows
-- inserted by one seed script share the exact same created_at
-- (now() is fixed for the whole transaction in Postgres), so
-- `ORDER BY created_at` had no real tiebreaker and could return
-- rows in an arbitrary order. order_index fixes this permanently.
-- =========================================================

alter table public.topics add column if not exists order_index integer not null default 0;
alter table public.projects add column if not exists order_index integer not null default 0;

-- ===================== STAGE 1 =====================
update public.topics set order_index = 1 where stage_id = (select id from public.stages where number = 1) and title = 'Introduction to Robotics';
update public.topics set order_index = 2 where stage_id = (select id from public.stages where number = 1) and title = 'Basic Electronics';
update public.topics set order_index = 3 where stage_id = (select id from public.stages where number = 1) and title = 'Tools & Workshop Skills';
update public.topics set order_index = 4 where stage_id = (select id from public.stages where number = 1) and title = 'Breadboard & Circuit Building';
update public.topics set order_index = 5 where stage_id = (select id from public.stages where number = 1) and title = 'Arduino Fundamentals';
update public.topics set order_index = 6 where stage_id = (select id from public.stages where number = 1) and title = 'ESP32 Fundamentals';
update public.topics set order_index = 7 where stage_id = (select id from public.stages where number = 1) and title = 'Tinkercad';
update public.topics set order_index = 8 where stage_id = (select id from public.stages where number = 1) and title = 'Digital, Analog and PWM';
update public.topics set order_index = 9 where stage_id = (select id from public.stages where number = 1) and title = 'Sensors';
update public.topics set order_index = 10 where stage_id = (select id from public.stages where number = 1) and title = 'Motors & motor drivers';

update public.projects set order_index = 1 where stage_id = (select id from public.stages where number = 1) and title = 'Bluetooth Controlled Car';
update public.projects set order_index = 2 where stage_id = (select id from public.stages where number = 1) and title = 'Obstacle Avoiding Car';

-- ===================== STAGE 2 =====================
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

-- ===================== STAGE 3 =====================
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

-- ===================== STAGE 4 =====================
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
