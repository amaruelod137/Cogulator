import 'package:basic_calculator/button_values.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class TutorialNode {
  String value;
  TutorialNode? left;
  TutorialNode? right;

  TutorialNode(this.value, {this.left, this.right});

  bool get isLeaf => left == null && right == null;
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String expression = "";

  String formula = "";

  String correctAnswer = "";
  String promptMessage = "";

  bool canRefresh = false;
  bool isGuessing = false;

  // variables for dual purpose evaluate button
  Timer? revealTimer;
  double holdProgress = 0.0;
  bool longPressTriggered = false;

  // display variables
  List<String> incorrectGuesses = [];
  Set<String> pressedButtons = {};
  Color promptColor = Colors.black;
  double promptScale = 1.0;
  Timer? promptTimer;

  // tutorial page variables
  bool showTutorialHint = false;
  List<String> tutorialSteps = [];
  int helpPage = 0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double horizontalPadding = 12;
    final buttonAreaWidth = screenSize.width - (horizontalPadding * 2);
    return Scaffold(
      backgroundColor: const Color(0xFF067D79),
      body: SafeArea(
        bottom: false,
        child: Stack(
          // padding: const EdgeInsetsGeometry.all(2),
          children: [
            Column(
              children: [
                const SizedBox(height: 40),

                Expanded(
                  child: Row(
                    children: [
                      // Left history panel
                      buildPanel(
                        title: "Guesses",
                        width: 90,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: incorrectGuesses.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 6,
                              ),
                              child: Text(
                                incorrectGuesses[incorrectGuesses.length -
                                    index -
                                    1],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Entire Display
                      Expanded(
                        child: buildPanel(
                          title: promptMessage.isEmpty
                              ? "Calculator"
                              : promptMessage,
                          child: SingleChildScrollView(
                            reverse: true,
                            child: Container(
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.fromLTRB(8, 40, 8, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const SizedBox(height: 4),

                                  // Main / Result Display
                                  Text(
                                    expression.isEmpty ? "0" : expression,
                                    style: const TextStyle(
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),

                                  const SizedBox(height: 12),

                                  // small formula display
                                  Text(
                                    formula,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Color.fromARGB(255, 67, 67, 67),
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isGuessing)
                  Container(
                    alignment: Alignment.topRight,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),

                    child: Text(
                      "💡 For answer hold '='",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (isGuessing == false) const SizedBox(height: 53.5),

                // buttons
                Wrap(
                  children: Btn.buttonValues
                      .map(
                        (value) => SizedBox(
                          width: value == Btn.lpar || value == Btn.rpar
                              ? buttonAreaWidth / 8
                              : (buttonAreaWidth / 4),
                          height: screenSize.width / 5,
                          child: buildButton(value),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    iconSize: 28,
                    onPressed: () {
                      setState(() {
                        showTutorialHint = false;
                      });

                      generateTutorial(formula);
                      showHelpPopup();
                    },
                  ),

                  if (showTutorialHint)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 49, 50, 114),
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 1),
                          left: BorderSide(color: Colors.white, width: 1),
                          right: BorderSide(color: Color(0xFF1F2050), width: 2),
                          bottom: BorderSide(
                            color: Color(0xFF1F2050),
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        "<< Step-by-step guide",
                        style: TextStyle(
                          color: Color.fromARGB(255, 200, 200, 200),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDialogButton({
    required String text,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;

    return Container(
      width: 70,
      height: 38,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white, width: 2),
          left: BorderSide(color: Colors.white, width: 2),
          right: BorderSide(color: Color(0xFF808080), width: 2),
          bottom: BorderSide(color: Color(0xFF808080), width: 2),
        ),
      ),
      child: Material(
        color: disabled ? const Color(0xFFD8D8D8) : const Color(0xFFC8C8C8),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 20,
                color: disabled ? Colors.grey : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButton(value) {
    final pressed = pressedButtons.contains(value);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: pressed ? const Color(0xFF808080) : Colors.white,
              width: 2,
            ),
            left: BorderSide(
              color: pressed ? const Color(0xFF808080) : Colors.white,
              width: 2,
            ),
            right: BorderSide(
              color: pressed ? Colors.white : const Color(0xFF808080),
              width: 2,
            ),
            bottom: BorderSide(
              color: pressed ? Colors.white : const Color(0xFF808080),
              width: 2,
            ),
          ),
        ),

        child: Material(
          color: getBtnColor(value),
          clipBehavior: Clip.hardEdge,

          
          child: InkWell(
            // tap/hold
            onTapDown: (_) {
              setState(() {
                pressedButtons.add(value);
              });
              if (value == Btn.calculate) {
                startRevealHold();
              }
            },

            onTapUp: (_) {
              setState(() {
                pressedButtons.remove(value);
              });
              if (value == Btn.calculate) {
                cancelRevealHold();
              }
            },

            onTapCancel: () {
              setState(() {
                pressedButtons.remove(value);
              });
              if (value == Btn.calculate) {
                cancelRevealHold();
              }
            },

            // regualar tap
            onTap: () {
              if (value == Btn.calculate && longPressTriggered) {
                longPressTriggered = false;
                return;
              }
              onBtnTap(value);
            },

            child: Stack(
              alignment: Alignment.center,
              children: [
                if (value == Btn.calculate && holdProgress > 0)
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: holdProgress,
                      strokeWidth: 4,
                    ),
                  ),

                Text(
                  value,
                  style: TextStyle(
                    color:
                        [
                          Btn.del,
                          Btn.clr,
                          Btn.multiply,
                          Btn.divide,
                          Btn.subtract,
                          Btn.add,
                          Btn.calculate,
                        ].contains(value)
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPanel({
    required String title,
    required Widget child,
    double? width,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white, width: 2),
          left: BorderSide(color: Colors.white, width: 2),
          right: BorderSide(color: Color(0xFF808080), width: 2),
          bottom: BorderSide(color: Color(0xFF808080), width: 2),
        ),
      ),
      child: Column(
        children: [
          // Thick title bar
          Container(
            height: 42,
            width: double.infinity,
            // padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 200, 200, 200),
              border: Border(
                bottom: BorderSide(
                  color: Color.fromARGB(255, 200, 200, 200),
                  width: 2,
                ),
              ),
            ),

            alignment: Alignment.center,

            child: AnimatedScale(
              scale: title == promptMessage ? promptScale : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Text(
                title.toUpperCase(),
                // textAlign: TextAlign.center,
                style: TextStyle(
                  color: title == promptMessage ? promptColor : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Panel contents
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFCFB),
                border: Border(
                  top: BorderSide(color: Color(0xFF808080), width: 2),
                  left: BorderSide(color: Color(0xFF808080), width: 2),
                  right: BorderSide(color: Colors.white, width: 2),
                  bottom: BorderSide(color: Colors.white, width: 2),
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // Button functions
  void onBtnTap(String value) {
    if (value == Btn.del) {
      delete();
      return;
    }

    if (value == Btn.clr) {
      clearAll();
      return;
    }

    if (value == Btn.per) {
      convertToPercentage();
      return;
    }

    if (value == Btn.calculate) {
      if (isGuessing) {
        checkGuess();
      } else {
        calculate();
      }
      return;
    }

    if (canRefresh == true) {
      clearAll();
      appendValue(value);
      canRefresh = false;
    } else {
      appendValue(value);
    }
  }

  // calculation function
  void calculate() {
    if (expression.isEmpty) return;

    try {
      final result = evaluateExpression(expression);

      setState(() {
        formula = expression;
        expression = "";
        correctAnswer = "$result";
        promptMessage = "Please try to guess first:";
        isGuessing = true;
        showTutorialHint = true;
      });
    } catch (e) {
      setState(() {
        promptMessage = "Invalid expression";
      });
    }
  }

  // parse + evaluate
  double evaluateExpression(String expr) {
    expr = expr.replaceAll(Btn.multiply, "*");
    expr = expr.replaceAll(Btn.divide, "/");

    GrammarParser p = GrammarParser();
    Expression exp = p.parse(expr);

    ContextModel cm = ContextModel();

    return exp.evaluate(EvaluationType.REAL, cm);
  }

  // long hold to reveal answer

  void revealAnswer() {
    setState(() {
      expression = correctAnswer;
      promptMessage = "Answer revealed";
      isGuessing = false;
      canRefresh = true;
    });
  }

  // start hold function
  void startRevealHold() {
    // if (isGuessing) return;

    holdProgress = 0;

    //milliseconds
    const totalDuration = 2500;
    const tickRate = 50;

    revealTimer?.cancel();

    revealTimer = Timer.periodic(const Duration(milliseconds: tickRate), (
      timer,
    ) {
      setState(() {
        holdProgress += tickRate / totalDuration;
      });
      if (holdProgress >= 1) {
        timer.cancel();

        holdProgress = 0;

        longPressTriggered = true;

        revealAnswer();
      }
    });
  }

  // cancel hold function
  void cancelRevealHold() {
    revealTimer?.cancel();

    if (holdProgress > 0) {
      setState(() {
        holdProgress = 0;
      });
    }
  }

  // function to check the user's guess
  void checkGuess() {
    if (expression.isEmpty) return;

    final guess = double.tryParse(expression);
    final answer = double.tryParse(correctAnswer);

    if (guess != null && answer != null && guess == answer) {
      setState(() {
        promptMessage = "You did it :)";
        isGuessing = false;
        canRefresh = true;
      });

      animatePrompt(Colors.green);
    } else {
      setState(() {
        incorrectGuesses.add(expression);
        promptMessage = "Incorrect :(";
        expression = "";
      });

      animatePrompt(Colors.red);
      HapticFeedback.mediumImpact();
    }
  }

  // convert to percentage function
  void convertToPercentage() {
    if (expression.isEmpty) return;

    try {
      final result = evaluateExpression(expression);

      setState(() {
        expression = (result / 100).toString();
      });
    } catch (_) {
      setState(() {
        promptMessage = "Invalid percentage";
      });
    }
  }

  // clear function
  void clearAll() {
    setState(() {
      formula = "";
      expression = "";
      promptMessage = "";
      isGuessing = false;
      correctAnswer = "";
      incorrectGuesses = [];
      showTutorialHint = false;
    });
  }

  // delete function
  void delete() {
    if (expression.isEmpty) return;

    setState(() {
      expression = expression.substring(0, expression.length - 1);
    });
  }

  void appendValue(String value) {
    expression += value;
    setState(() {});
  }

  // UI HELPER FUNCTIONS
  Color getBtnBorderColor(String value) {
    final color = getBtnColor(value);

    return Color.fromARGB(
      255,
      (color.r * 0.75).round(),
      (color.g * 0.75).round(),
      (color.b * 0.75).round(),
    );
  }

  void animatePrompt(Color color) {
    promptTimer?.cancel();

    setState(() {
      promptColor = color;
      promptScale = 1.15;
    });

    promptTimer = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        promptScale = 1.0;
        promptColor = Colors.black;
      });
    });
  }

  // modal overlay for tutorial popup window
  void showHelpPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(8),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.85,

                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 200, 200, 200),
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 2),
                    left: BorderSide(color: Colors.white, width: 2),
                    right: BorderSide(color: Color(0xFF808080), width: 2),
                    bottom: BorderSide(color: Color(0xFF808080), width: 2),
                  ),
                ),

                child: Column(
                  children: [
                    // Title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: const Color.fromARGB(255, 200, 200, 200),
                      child: const Text(
                        "Instructions",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // Tutorial content
                    Expanded(
                      child: Center(
                        child: Text(
                          tutorialSteps.isEmpty
                              ? "No tutorial available yet !\nEnter a formula to generate one ;)"
                              : tutorialSteps[helpPage],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // Bottom buttons
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // previous page arrow
                          buildDialogButton(
                            text: "◀",
                            onTap: helpPage > 0
                                ? () {
                                    setDialogState(() {
                                      helpPage--;
                                    });
                                  }
                                : null,
                          ),
                          // next page arrow
                          buildDialogButton(
                            text: "▶",
                            onTap: helpPage < tutorialSteps.length - 1
                                ? () {
                                    setDialogState(() {
                                      helpPage++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ##########
  Color getBtnColor(value) {
    return [Btn.del, Btn.clr].contains(value)
        ? Color.fromARGB(255, 49, 50, 114)
        : [
            Btn.multiply,
            Btn.add,
            Btn.subtract,
            Btn.divide,
            Btn.calculate,
          ].contains(value)
        ? Color.fromARGB(255, 255, 203, 0)
        : Color.fromARGB(255, 200, 200, 200);
  }

  // Tutorial Engine
  // Building expression trees
  List<String> tokenize(String expr) {
    List<String> tokens = [];
    String number = "";

    for (int i = 0; i < expr.length; i++) {
      String c = expr[i];

      if ("0123456789.".contains(c)) {
        number += c;
      } else {
        if (number.isNotEmpty) {
          tokens.add(number);
          number = "";
        }

        if ("()+-×÷".contains(c)) {
          tokens.add(c);
        }
      }
    }

    if (number.isNotEmpty) {
      tokens.add(number);
    }

    return tokens;
  }

  int findMainOperator(List<String> tokens) {
    int bracketDepth = 0;

    for (int i = tokens.length - 1; i >= 0; i--) {
      String token = tokens[i];

      if (token == ")")
        bracketDepth++;
      else if (token == "(")
        bracketDepth--;

      if (bracketDepth != 0) continue;

      if (token == "+" || token == "-") {
        return i;
      }
    }

    // Second pass for × and ÷

    bracketDepth = 0;

    for (int i = tokens.length - 1; i >= 0; i--) {
      String token = tokens[i];

      if (token == ")")
        bracketDepth++;
      else if (token == "(")
        bracketDepth--;

      if (bracketDepth != 0) continue;

      if (token == "×" || token == "÷") {
        return i;
      }
    }

    return -1;
  }

  // recursive function to build expression tree
  TutorialNode buildTree(List<String> tokens) {
    // Single number
    if (tokens.length == 1) {
      return TutorialNode(tokens[0]);
    }

    // Remove outer brackets
    if (tokens.first == "(" && tokens.last == ")") {
      int depth = 0;
      bool removable = true;

      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i] == "(") depth++;
        if (tokens[i] == ")") depth--;

        if (depth == 0 && i != tokens.length - 1) {
          removable = false;
          break;
        }
      }

      if (removable) {
        return buildTree(tokens.sublist(1, tokens.length - 1));
      }
    }

    int opIndex = findMainOperator(tokens);

    if (opIndex == -1) {
      throw Exception("Couldn't parse expression.");
    }

    return TutorialNode(
      tokens[opIndex],
      left: buildTree(tokens.sublist(0, opIndex)),
      right: buildTree(tokens.sublist(opIndex + 1)),
    );
  }

  // HELPER FUNCTIONS:
  // 1. tree evaluating function -> evaluates a branch
  double evaluateTree(TutorialNode node) {
    if (node.isLeaf) {
      return double.parse(node.value);
    }

    final left = evaluateTree(node.left!);
    final right = evaluateTree(node.right!);

    switch (node.value) {
      case "+":
        return left + right;

      case "-":
        return left - right;

      case "×":
        return left * right;

      case "÷":
        return left / right;
    }

    throw Exception("Unknown operator");
  }

  // 2. turn tree back into text
  String treeToExpression(TutorialNode node) {
    if (node.isLeaf) {
      return node.value;
    }

    String left = treeToExpression(node.left!);
    String right = treeToExpression(node.right!);

    if (!node.left!.isLeaf) {
      left = "($left)";
    }

    if (!node.right!.isLeaf) {
      right = "($right)";
    }

    return "$left${node.value}$right";
  }

  // 4. swap tree nodes
  void replaceNode(
    TutorialNode current,
    TutorialNode target,
    TutorialNode replacement,
  ) {
    if (current.left == target) {
      current.left = replacement;
      return;
    }

    if (current.right == target) {
      current.right = replacement;
      return;
    }

    if (current.left != null) {
      replaceNode(current.left!, target, replacement);
    }

    if (current.right != null) {
      replaceNode(current.right!, target, replacement);
    }
  }

  // 5. search the tree
  TutorialNode? findFirstSolvable(TutorialNode node) {
    if (node.isLeaf) return null;

    // left subtree first
    final left = findFirstSolvable(node.left!);
    if (left != null) return left;

    // then right subtree
    final right = findFirstSolvable(node.right!);
    if (right != null) return right;

    // if both children are numbers,
    // this node is ready to solve
    if (isNumberNode(node.left!) && isNumberNode(node.right!)) {
      return node;
    }

    return null;
  }

  // 6.
  bool isNumberNode(TutorialNode node) {
    return node.isLeaf && double.tryParse(node.value) != null;
  }

  // Tutorial Engine
  void generateTutorial(String expr) {
    helpPage = 0;
    tutorialSteps.clear();

    // TEST //

    TutorialNode tree = buildTree(tokenize(expr));

    tutorialSteps.add("Your Expression:\n$expr");

    while (!tree.isLeaf) {
      TutorialNode? node = findFirstSolvable(tree);

      if (node == null) break;

      double result = evaluateTree(node);

      tutorialSteps.add(
        "Evaluate the following:\n\n${treeToExpression(node)} = $result",
      );

      TutorialNode replacement = TutorialNode(result.toString());

      if (node == tree) {
        tree = replacement;
      } else {
        replaceNode(tree, node, replacement);
      }

      tutorialSteps.add("The Expression becomes:\n\n${treeToExpression(tree)}");
    }

    tutorialSteps.add("Answer:\n${tree.value}");
  }
}
