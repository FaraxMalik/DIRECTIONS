class QuizQuestion {
  final String question;
  final List<String> options;
  QuizQuestion({required this.question, required this.options});
}

final List<QuizQuestion> quizQuestions = [
  QuizQuestion(
    question: 'Imagine you just finished a detox period. What is the first thing you want to do?',
    options: ['Travel somewhere new', 'Start a creative project', 'Meet friends', 'Read a book'],
  ),
  QuizQuestion(
    question: 'Which MBTI type do you relate to most?',
    options: ['INTJ', 'ENFP', 'ISTP', 'ESFJ'],
  ),
  QuizQuestion(
    question: 'Which OCEAN personality trait is most dominant for you?',
    options: ['Openness', 'Conscientiousness', 'Extraversion', 'Agreeableness'],
  ),
  QuizQuestion(
    question: 'You have a free day. What do you do?',
    options: ['Explore outdoors', 'Learn something new', 'Help someone', 'Relax at home'],
  ),
  QuizQuestion(
    question: 'Which activity excites you most?',
    options: ['Solving puzzles', 'Leading a team', 'Creating art', 'Helping others'],
  ),
  QuizQuestion(
    question: 'If you could master any skill instantly, what would it be?',
    options: ['Coding', 'Public speaking', 'Painting', 'Negotiation'],
  ),
  QuizQuestion(
    question: 'What motivates you most?',
    options: ['Achievement', 'Connection', 'Creativity', 'Security'],
  ),
  QuizQuestion(
    question: 'How do you handle stress?',
    options: ['Exercise', 'Talk to friends', 'Meditate', 'Work harder'],
  ),
  QuizQuestion(
    question: 'Which environment do you thrive in?',
    options: ['Fast-paced', 'Collaborative', 'Independent', 'Structured'],
  ),
  QuizQuestion(
    question: 'If you could do any job for a day, what would it be?',
    options: ['Entrepreneur', 'Scientist', 'Artist', 'Teacher'],
  ),
];
