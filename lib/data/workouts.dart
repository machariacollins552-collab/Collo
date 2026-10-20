/// Beginner-friendly home workouts. No gym and no equipment needed.
library;

/// One exercise in a workout. Either timed ([seconds]) or rep-based ([reps]).
class WorkoutStep {
  const WorkoutStep({
    required this.name,
    required this.howTo,
    this.seconds,
    this.reps,
    this.isRest = false,
  });

  final String name;
  final String howTo;

  /// Timed exercises count down from this value.
  final int? seconds;

  /// Rep-based exercises show this text, for example `10 reps`.
  final String? reps;
  final bool isRest;

  bool get isTimed => seconds != null;
}

class Workout {
  const Workout({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.level,
    required this.steps,
    this.lowImpact = true,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Approximate total time in minutes.
  final int minutes;
  final String level;
  final List<WorkoutStep> steps;
  final bool lowImpact;
}

const String kWorkoutSafety =
    'Move at a comfortable pace and stop if you feel dizzy, short of breath, chest pain or sharp pain. '
    'If you have a health condition, are pregnant or have not exercised for a long time, check with a '
    'doctor before starting. These routines are general fitness ideas, not medical advice.';

const WorkoutStep _rest20 = WorkoutStep(
  name: 'Rest',
  howTo: 'Breathe slowly and sip water.',
  seconds: 20,
  isRest: true,
);

const WorkoutStep _rest30 = WorkoutStep(
  name: 'Rest',
  howTo: 'Breathe slowly and sip water.',
  seconds: 30,
  isRest: true,
);

const List<Workout> kWorkouts = <Workout>[
  Workout(
    id: 'gentle_start',
    title: 'Gentle Start',
    subtitle: 'A kind first session to wake up your body.',
    minutes: 12,
    level: 'Beginner',
    steps: <WorkoutStep>[
      WorkoutStep(
        name: 'March in place',
        howTo: 'Lift your knees to a comfortable height and swing your arms.',
        seconds: 60,
      ),
      WorkoutStep(
        name: 'Arm circles',
        howTo: 'Small circles forward for 15 seconds, then backward for 15 seconds.',
        seconds: 30,
      ),
      WorkoutStep(
        name: 'Wall push-ups',
        howTo: 'Hands on a wall at chest height. Bend your elbows, then press away. Keep your body straight.',
        reps: '10 reps',
      ),
      _rest20,
      WorkoutStep(
        name: 'Chair squats',
        howTo: 'Stand in front of a chair. Sit back until you lightly touch it, then stand tall.',
        reps: '10 reps',
      ),
      WorkoutStep(
        name: 'Standing knee lifts',
        howTo: 'Lift one knee at a time toward your waist. Hold a wall if you need balance.',
        seconds: 40,
      ),
      _rest20,
      WorkoutStep(
        name: 'Calf raises',
        howTo: 'Rise onto your toes, pause, and lower slowly.',
        reps: '12 reps',
      ),
      WorkoutStep(
        name: 'Gentle stretch',
        howTo: 'Reach up tall, then fold forward with soft knees. Breathe slowly.',
        seconds: 45,
      ),
    ],
  ),
  Workout(
    id: 'full_body_basics',
    title: 'Full Body Basics',
    subtitle: 'Legs, arms and core in one simple circuit.',
    minutes: 20,
    level: 'Beginner',
    steps: <WorkoutStep>[
      WorkoutStep(
        name: 'Warm-up march',
        howTo: 'March in place, then add big arm swings.',
        seconds: 90,
      ),
      WorkoutStep(
        name: 'Chair squats',
        howTo: 'Sit back to a chair and stand up tall. Keep your chest lifted.',
        reps: '12 reps',
      ),
      WorkoutStep(
        name: 'Incline push-ups',
        howTo: 'Hands on a sturdy table or bed edge. Lower your chest, then press up.',
        reps: '8 reps',
      ),
      _rest30,
      WorkoutStep(
        name: 'Reverse lunges',
        howTo: 'Step one foot back, lower gently, then return. Alternate legs.',
        reps: '8 per leg',
      ),
      WorkoutStep(
        name: 'Glute bridges',
        howTo: 'Lie on your back, knees bent. Lift your hips, squeeze, and lower slowly.',
        reps: '12 reps',
      ),
      _rest30,
      WorkoutStep(
        name: 'Bird dog',
        howTo: 'On hands and knees, reach one arm and the opposite leg out. Alternate sides slowly.',
        reps: '8 per side',
      ),
      WorkoutStep(
        name: 'Plank on knees',
        howTo: 'Forearms down, knees down, body in a straight line. Breathe steadily.',
        seconds: 20,
      ),
      _rest30,
      WorkoutStep(
        name: 'Repeat: chair squats',
        howTo: 'One more round of squats. Slow and controlled.',
        reps: '10 reps',
      ),
      WorkoutStep(
        name: 'Cool-down stretch',
        howTo: 'Stretch your thighs, chest and shoulders. Hold each position gently.',
        seconds: 90,
      ),
    ],
  ),
  Workout(
    id: 'lower_body',
    title: 'Lower Body and Glutes',
    subtitle: 'Strong legs help with everyday life and burn energy.',
    minutes: 15,
    level: 'Beginner',
    steps: <WorkoutStep>[
      WorkoutStep(
        name: 'Warm-up march',
        howTo: 'March with a gentle swing of the arms.',
        seconds: 60,
      ),
      WorkoutStep(
        name: 'Sit-to-stand',
        howTo: 'Use a chair. Stand up fully and sit down slowly.',
        reps: '12 reps',
      ),
      WorkoutStep(
        name: 'Side leg raises',
        howTo: 'Hold a wall. Lift one leg out to the side, then lower. Switch legs halfway.',
        reps: '10 per leg',
      ),
      _rest20,
      WorkoutStep(
        name: 'Glute bridges',
        howTo: 'Lift your hips and hold for one second at the top.',
        reps: '15 reps',
      ),
      WorkoutStep(
        name: 'Reverse lunges',
        howTo: 'Hold a wall if needed. Step back and lower gently.',
        reps: '8 per leg',
      ),
      _rest20,
      WorkoutStep(
        name: 'Wall sit',
        howTo: 'Back against a wall, knees bent comfortably. Hold, breathing steadily.',
        seconds: 20,
      ),
      WorkoutStep(
        name: 'Calf raises',
        howTo: 'Slow up, slow down.',
        reps: '15 reps',
      ),
      WorkoutStep(
        name: 'Quad and hamstring stretch',
        howTo: 'Hold each stretch gently for about 20 seconds per side.',
        seconds: 60,
      ),
    ],
  ),
  Workout(
    id: 'core_posture',
    title: 'Core and Posture',
    subtitle: 'Gentle core work that is kind to your back.',
    minutes: 12,
    level: 'Beginner',
    steps: <WorkoutStep>[
      WorkoutStep(
        name: 'Cat-cow',
        howTo: 'On hands and knees, round your back, then lift your chest. Move with your breath.',
        seconds: 45,
      ),
      WorkoutStep(
        name: 'Dead bug',
        howTo: 'Lie on your back, arms up, knees bent. Lower opposite arm and leg slowly, then switch.',
        reps: '8 per side',
      ),
      WorkoutStep(
        name: 'Bird dog',
        howTo: 'Reach opposite arm and leg. Keep your hips level.',
        reps: '8 per side',
      ),
      _rest20,
      WorkoutStep(
        name: 'Plank on knees',
        howTo: 'Forearms down. Keep a straight line from head to knees.',
        seconds: 20,
      ),
      WorkoutStep(
        name: 'Glute bridges',
        howTo: 'Squeeze your glutes as you lift.',
        reps: '12 reps',
      ),
      _rest20,
      WorkoutStep(
        name: 'Wall angels',
        howTo: 'Back against a wall, slide your arms up and down like a snow angel.',
        reps: '10 reps',
      ),
      WorkoutStep(
        name: "Child's pose",
        howTo: 'Sit back on your heels, reach forward, and breathe slowly.',
        seconds: 45,
      ),
    ],
  ),
  Workout(
    id: 'quiet_cardio',
    title: 'Quiet Low-Impact Cardio',
    subtitle: 'No jumping, so it is gentle on knees and neighbours.',
    minutes: 15,
    level: 'Beginner',
    steps: <WorkoutStep>[
      WorkoutStep(
        name: 'Easy march',
        howTo: 'March in place at a conversational pace.',
        seconds: 60,
      ),
      WorkoutStep(
        name: 'Step jacks',
        howTo: 'Step one foot out while raising your arms, then switch. No jumping.',
        seconds: 40,
      ),
      WorkoutStep(
        name: 'Side steps with arm swing',
        howTo: 'Step wide to each side and swing your arms.',
        seconds: 40,
      ),
      _rest20,
      WorkoutStep(
        name: 'Shadow boxing',
        howTo: 'Throw slow punches forward with a soft bend in your knees.',
        seconds: 40,
      ),
      WorkoutStep(
        name: 'Fast march',
        howTo: 'Pick up the pace and drive your arms.',
        seconds: 40,
      ),
      _rest20,
      WorkoutStep(
        name: 'Heel digs',
        howTo: 'Alternate pushing a heel forward while swinging opposite arm.',
        seconds: 40,
      ),
      WorkoutStep(
        name: 'Knee lifts with reach',
        howTo: 'Lift one knee while reaching the opposite hand to it.',
        seconds: 40,
      ),
      _rest20,
      WorkoutStep(
        name: 'Cool-down walk',
        howTo: 'Walk slowly around the room, letting your heart rate settle.',
        seconds: 90,
      ),
    ],
  ),
  Workout(
    id: 'evening_stretch',
    title: 'Evening Stretch',
    subtitle: 'Wind down, ease stiffness and prepare for sleep.',
    minutes: 8,
    level: 'All levels',
    steps: <WorkoutStep>[
      WorkoutStep(
        name: 'Neck rolls',
        howTo: 'Drop your chin and roll your head slowly from side to side.',
        seconds: 30,
      ),
      WorkoutStep(
        name: 'Shoulder rolls',
        howTo: 'Big slow circles, forward then backward.',
        seconds: 30,
      ),
      WorkoutStep(
        name: 'Seated forward fold',
        howTo: 'Sit on the floor or bed, legs straight, and reach toward your toes without forcing.',
        seconds: 45,
      ),
      WorkoutStep(
        name: 'Figure-four stretch',
        howTo: 'Lie on your back, cross one ankle over the opposite knee, and gently pull. Switch sides halfway.',
        seconds: 60,
      ),
      WorkoutStep(
        name: 'Chest opener',
        howTo: 'Clasp your hands behind your back and lift gently.',
        seconds: 30,
      ),
      WorkoutStep(
        name: 'Slow breathing',
        howTo: 'Breathe in for four counts and out for six counts.',
        seconds: 90,
      ),
    ],
  ),
];

Workout? workoutById(String id) {
  for (final w in kWorkouts) {
    if (w.id == id) return w;
  }
  return null;
}

/// A rotating suggestion so the home screen offers something different each day.
Workout suggestedWorkoutFor(DateTime day) {
  final index = (day.difference(DateTime(day.year, 1, 1)).inDays) % kWorkouts.length;
  return kWorkouts[index];
}

const List<String> kDailyTips = <String>[
  'Drink a glass of water before each meal. It is a small habit with a quiet payoff.',
  'A 10-minute walk after a meal counts. Short and regular beats long and rare.',
  'Prepare tomorrow\'s food tonight. A plan beats willpower.',
  'Beans, ndengu and eggs are budget-friendly proteins that keep you full.',
  'Sleep is part of weight management. Aim for a steady bedtime.',
  'Weigh yourself at the same time of day, no more than once or twice a week.',
  'Fill half your plate with vegetables first, then add the rest.',
  'Progress is not a straight line. Look at weeks, not single days.',
  'Walk part of your commute or take the stairs when you can.',
  'Cut sugar in tea a little at a time. Your taste adjusts within weeks.',
  'Eat slowly and put your fork down between bites.',
  'Celebrate non-scale wins: energy, sleep, how your clothes fit.',
  'Missed a day? Simply begin again at the next meal. No guilt needed.',
];
