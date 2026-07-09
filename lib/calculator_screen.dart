import 'package:basic_calculator/button_values.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:async';


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
  bool isHoldingEquals = false;
  bool longPressTriggered = false;

  // display functions
  List<String> incorrectGuesses = [];

  @override
  Widget build(BuildContext context) {
    final screenSize=MediaQuery.of(context).size;
    const double horizontalPadding = 12;
    final buttonAreaWidth = screenSize.width - (horizontalPadding * 2);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsGeometry.all(2),
          child: Column(
            children: [
            const SizedBox(height: 40,),
            
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
                            incorrectGuesses[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
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
                          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                          child: Column( 
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [

                            
                          
                              const SizedBox(height: 8),
                              // Main / Result Display
                              Text(
                                expression.isEmpty
                                  ? "0"
                                  : expression, 
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.end,
                              ),


                              // small formula display
                              Text(
                                formula,
                                style: const TextStyle(
                                  fontSize: 36,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.end,
                              ),
                              

                            ],
                          ),
                        ),
                      ),
                    ),)
                ],
                ),
                ),


            Container(
              alignment: Alignment.topRight,
              padding: EdgeInsets.symmetric(vertical: 15, horizontal:20),
              child: Text(
                "💡 For answer hold '='",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            // buttons
            Wrap(
              children: Btn.buttonValues
                  .map(
                    (value) => SizedBox(
                      width: value == Btn.lpar || value == Btn.rpar 
                      ? buttonAreaWidth / 8
                      : (buttonAreaWidth / 4),
                      height: screenSize.width / 5,
                      child: buildButton(value)
                    ),
                  )
                  .toList(),
            )
          ],),
      ))
    );
  }

  Widget buildButton(value){
    return Padding(
      padding: const EdgeInsets.all(2.0),
      /*child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(221, 0, 0, 0),
              blurRadius: 2,
              offset: Offset(2, 2),
            ),
          ],
        ),*/
      child: Material(
        color: getBtnColor(value),
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          side: BorderSide(
//           color: Color.lerp(getBtnBorderColor(value), Colors.black, 0.25)!,
            color: getBtnBorderColor(value).withValues(alpha: 0.8),
            width: 2,
          ),
          borderRadius: BorderRadius.zero//BorderRadius.circular(100),
        ),

        child: InkWell(
          // tap/hold 
          onTapDown: (_) {
            if (value == Btn.calculate) {
              startRevealHold();
            }
          },

          onTapUp: (_) {
            if (value == Btn.calculate) {
              cancelRevealHold();
            }
          },

          onTapCancel: () {
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
/*
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 36),
*/
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
                  color: [
                    Btn.multiply,
                    Btn.divide,
                    Btn.add,
                    Btn.subtract,
                    Btn.calculate,
                    Btn.del,
                    Btn.clr,
                  ].contains(value)
                    ? Colors.white
                    : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
              ),
            ],
          )
        ),
      ),
    ); 
  }


  Widget buildPanel({
    required String title,
    required Widget child,
    double? width,
    Color titleColor = Colors.amber,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 2,
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
              color: Colors.grey,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 2,
                ),
              ),
            ),

            alignment: Alignment.center,

            child: Text(
              title.toUpperCase(),
              // textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          // Panel contents
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }



  // Button functions
  void onBtnTap(String value){
    if(value == Btn.del) {
      delete();
      return;
    }
    
    if(value == Btn.clr) {
      clearAll();
      return;
    }

    if(value == Btn.per){
      convertToPercentage();
      return;
    }

    if(value == Btn.calculate){
      
      if(isGuessing){
        checkGuess();
      }
      else{
        calculate();
      }
      return;
    }

    if(canRefresh == true){
      clearAll();
      appendValue(value);
      canRefresh = false;
    }
    else{
      appendValue(value);
    }
  }

  // calculation function
  void calculate(){
    if (expression.isEmpty) return;

    try{
      final result = evaluateExpression(expression);
      
      setState(() {
        formula = expression;
        expression = "";
        correctAnswer = "$result";
        promptMessage = "Please try to guess first:";
        isGuessing = true;
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

  void revealAnswer(){
    if (expression.isEmpty) return;

    try {
      final result = evaluateExpression(expression);
      
      setState(() {
        formula = expression;
        expression = "$result";
        promptMessage = "Answer revealed";
        isGuessing = false;
        canRefresh = true;
      });
    } catch (e) {
      setState(() {
        promptMessage = "Invalid expression";
      });
    }
  }


  // start hold function
  void startRevealHold() {
    if (isGuessing) return;

    
    isHoldingEquals = true;
    holdProgress = 0;
    
     //milliseconds
    const totalDuration = 2500;
    const tickRate = 50;

    revealTimer?.cancel();

    revealTimer = Timer.periodic(
      const Duration(milliseconds: tickRate),
      (timer) {
        setState(() {
          holdProgress += tickRate / totalDuration;
        });
        if (holdProgress >= 1) {
          timer.cancel();

          holdProgress = 0;
          isHoldingEquals = false;

          longPressTriggered = true;

          revealAnswer();
        }
      },
    );
  }

  // cancel hold function
  void cancelRevealHold() {
    revealTimer?.cancel();

    if (holdProgress > 0) {
      setState(() {
        holdProgress = 0;
        isHoldingEquals = false;
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
        promptMessage = "Well done!";
        isGuessing = false;
        canRefresh = true;
      });
    } else {
      setState(() {
        incorrectGuesses.add(expression);
        promptMessage = "Try again";
        expression = "";
      });
    }
  }

  // convert to percentage function
  void convertToPercentage(){
    // TODO: rewrite for expression-based calculator
    if(expression.isEmpty) return;
    final number = double.tryParse(expression);

    if (number == null) {
      setState(() {
        promptMessage = "Invalid percentage";
      });
      return;
    }
    setState(() {
      expression = (number / 100).toString();
    });
  }


  // clear function
  void clearAll(){
    setState(() {

      formula="";
      expression = "";
      promptMessage = "";
      isGuessing = false;
      correctAnswer = "";
    });
  }

  // delete function
  void delete(){
    if(expression.isEmpty) return;

    setState(() {
      expression =
        expression.substring(0, expression.length - 1);
    });
  }

  void appendValue(String value){
    expression += value;
    setState(() {
    });
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
  // ##########
  Color getBtnColor(value){
    return [Btn.del, Btn.clr].contains(value)
        ?Colors.blueGrey
        :[
          Btn.multiply,
          Btn.add,
          Btn.subtract,
          Btn.divide,
          Btn.calculate,
        ].contains(value)
          ? Colors.orange
          : Colors.grey;// const Color.fromARGB(255, 47, 47, 47);
  }
}