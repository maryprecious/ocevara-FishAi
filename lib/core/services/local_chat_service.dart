import 'dart:math';

class LocalChatService {
  final Map<String, List<String>> _responses = {
    'fish': [
      "I can help you identify various fish! Are you looking for information on Tilapia, Carp, or maybe something restricted like a Juvenile Snapper?",
      "Fishing is all about patience. Which specific species are you targeting today?",
      "To catch more fish, try to match your bait to the local prey in the water."
    ],
    'time': [
      "The best time to fish is usually early morning or late evening when the water is cooler and fish are more active.",
      "Check the weather! Overcast days are often better for fishing than bright, sunny days.",
      "Tide changes are also a great time for coastal fishing. Are you near the ocean right now?"
    ],
    'bait': [
      "For freshwater fish like Tilapia or Carp, bread, corn, or worms work wonders.",
      "If you're targeting predators like Nile Perch, try using live bait or large lures that mimic smaller fish.",
      "Always make sure your hooks are sharp for the best hook-up rate!"
    ],
    'safety': [
      "Always wear a life jacket when fishing from a boat or near deep water.",
      "Check the local regulations in the 'Rules' section of the app to ensure you're fishing legally.",
      "Stay hydrated and wear sunscreen if you're out in the sun all day!"
    ],
    'ocevara': [
      "Ocevara AI is here to help you become a better angler and protect our oceans!",
      "You can use the Map to find the best spots, or the Calendar to see when it's safe to fish.",
      "Don't forget to check the dynamic catch sections in the Fish List!"
    ],
    'default': [
      "That's a great question! While I'm having a bit of trouble reaching my full expertise database right now, I can still offer some general fishing tips. What else would you like to know?",
      "I'm passionate about all things fishing and ocean life. Could you tell me more about your interests?",
      "I'm here to help! Feel free to ask about specific fish, techniques, or how to use the Ocevara app."
    ]
  };

  String getResponse(String userMessage) {
    final msg = userMessage.toLowerCase();
    
    if (msg.contains('time') || msg.contains('when')) {
      return _getRandomResponse('time');
    } else if (msg.contains('bait') || msg.contains('lure') || msg.contains('how to catch')) {
      return _getRandomResponse('bait');
    } else if (msg.contains('safety') || msg.contains('rule') || msg.contains('legal')) {
      return _getRandomResponse('safety');
    } else if (msg.contains('fish') || msg.contains('species') || msg.contains('tilapia')) {
      return _getRandomResponse('fish');
    } else if (msg.contains('app') || msg.contains('ocevara')) {
      return _getRandomResponse('ocevara');
    }
    
    return _getRandomResponse('default');
  }

  String _getRandomResponse(String category) {
    final list = _responses[category] ?? _responses['default']!;
    return list[Random().nextInt(list.length)];
  }
}
