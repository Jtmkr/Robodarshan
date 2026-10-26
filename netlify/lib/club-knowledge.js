// Everything the "Club help" assistant is allowed to know about Robodarshan.
//
// KEEP THIS FILE UP TO DATE. The assistant answers ONLY from this text, so a
// price or rule that is wrong here will be repeated to members. Anything not
// written here is answered with "I don't have that information" plus the
// club's contact details.
//
// This lives outside netlify/functions on purpose: every .js file directly
// inside that folder would be deployed as its own function. It is pulled into
// chat.js with require() and bundled with it.

module.exports = `
# About Robodarshan
- Robodarshan is the robotics and automation society of IIEST Shibpur (Indian Institute of Engineering Science and Technology, Shibpur), Howrah, West Bengal. It is a student-driven society.
- It gives students a platform to explore robotics, automation and IoT through sessions, workshops, competitions and projects.
- IIEST Shibpur was established in 1856 as the Calcutta Civil Engineering College and was renamed IIEST Shibpur in 2014.

# What the club does
- Sessions: weekly sessions on robotics and IoT topics, with good study material and hands-on practice.
- Workshops: held after every month, to introduce members to the latest equipment and technologies.
- Competitions: Robocon and Automation events are held every year to bring young people into the Indian robotics community. Others can participate too.
- Projects: members' project ideas are supported. Several projects are ongoing under the Robodarshan banner.
- Announcements appear on the home page of the website.

# Contact
- Email: robodarshan@gmail.com
- Address: IIEST, Botanical Garden Area, Howrah, West Bengal 711103
- The website has a Contact page with a message form: /pages/contact.html
- The Team page (/pages/team.html) lists the people behind the society.

# Merchandise (Merch page: /pages/merch.html)
- Official product: Robodarshan Official T-Shirt 2026, launched with an early bird offer.
- Price: Rs 379 with a name printed, Rs 359 without a name.
- To buy: use the "ORDER NOW" button on the Merch page, which opens the order form.
- No other merchandise items or prices are listed right now. For anything else, ask the club by email.

# Joining and roles
- To use the website's member features, log in with Google using your IIEST institute email, which ends with @students.iiests.ac.in. Other email domains are not accepted.
- After the first login you complete a registration form: institute email, full name, mobile number, enrollment number, personal email and a profile picture. Then you get access to the dashboard and Study Portal.
- Roles, from lowest to highest: Member, Rookie, Trainee, Veteran, Admin.
  - Member: the default role for everyone who registers. Session and project completions need approval by an admin.
  - Rookie: a member is promoted to Rookie automatically when their XP reaches the Rookie threshold. The threshold is calculated from the content: all the XP of Stage 1 and Stage 2 plus the Stage 3 session XP. At the time of writing that is about 670 XP, but it can change if XP values change; the dashboard shows the exact value. Rookies' sessions and projects are verified automatically, and a Rookie is paired with a Trainee mentor.
  - Trainee and Veteran: these roles are assigned by the club admins only. They are never earned automatically; for what is expected, members should ask the club's leaders. Trainees mentor Rookies and can assign projects and kits to them. Veterans oversee Rookies and Trainees and arrange the pairings.
  - Admin: manages the website and approvals.
- I do not have information about any other selection process, interviews, or fees. Do not guess; point the member to robodarshan@gmail.com.

# Study Portal and XP
- The Study Portal (/pages/learning-portal.html) has 4 stages: Stage 1 Robotics Beginner (Build), Stage 2 Robotics Intermediate (Control), Stage 3 Advanced Robotics (Autonomy), Stage 4 Professional and Research Robotics.
- Each stage has Sessions (attendance), Topics (lessons with a quiz) and Projects.
- Topics are completed by the member after attempting the quiz at least once, and are verified automatically. Sessions need attendance to be marked, and sessions and projects (for Members) need admin approval. Projects need a quiz attempt before they can be submitted for review.
- Completing items earns XP. Quizzes themselves do not change XP, and every attempt is saved so a member can retry.
- Stage 1 topics and the Bluetooth car project have full study material. Some later stages are still being prepared.

# Events (Events page: /pages/events.html)
- Robocon events: FireFix (autonomous firefighting challenge), GyroBot (a two-wheeled stability race), Autonomix (a 72-hour hardware and AI hackathon), LineX (line follower robot), Maze Runner.
- Other events shown as coming soon: Soccred Games, Death Race, AeroCraft, DronoCoid, Robo War, Illusion Runner.
- For dates, registration and rules of an event, direct people to the event's Details page on the Events page or to the club email. No dates are listed in this knowledge.

# Gallery and other pages
- Gallery: /pages/gallery.html
- About: /pages/about.html
- Dashboard (profile, XP, rank, mentors, kits): /pages/dashboard.html
`;
