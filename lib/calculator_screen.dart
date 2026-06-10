import 'package:basic_calculator/button_values.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';


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

  @override
  Widget build(BuildContext context) {
    final screenSize=MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
          // output
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(16),
                child: Column( 
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // small formula display
                    Text(
                      formula,
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.end,
                    ),

                    const SizedBox(height: 8),

                    // prompt message
                    Text(
                      //promptMessage,
                      correctAnswer,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),

                    const SizedBox(height: 8),
                    // Main / Result Display
                    Text(
                      expression.isEmpty
                        ? "0"
                        : expression, 
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ),
          ),
        
          // buttons
          Wrap(
            children: Btn.buttonValues
                .map(
                  (value) => SizedBox(
                    width: value == Btn.lpar || value == Btn.rpar 
                    ? screenSize.width / 8
                    : (screenSize.width / 4),
                    height: screenSize.width / 5,
                    child: buildButton(value)
                  ),
                )
                .toList(),
          )
        ],),
      )
    );
  }

  Widget buildButton(value){
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Material(
        color: getBtnColor(value),
        clipBehavior: Clip.hardEdge,
        shape: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.white24,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () => onBtnTap(value),
          child: Center(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 36,)),
          )
        ),
      ),
    );
  }


  // ##########
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

  double evaluateExpression(String expr) {
    expr = expr.replaceAll(Btn.multiply, "*");
    expr = expr.replaceAll(Btn.divide, "/");

    GrammarParser p = GrammarParser();
    Expression exp = p.parse(expr);

    ContextModel cm = ContextModel();

    return exp.evaluate(EvaluationType.REAL, cm);

    /*
    // solve parentheses first
    while (expr.contains("(")) {
      int close = expr.indexOf(")");
      if (close == -1) break;

      int open = expr.lastIndexOf("(", close);
      if (open == -1) break;

      String inner = expr.substring(open + 1, close);

      double innerResult = evaluateExpression(inner);

      expr = expr.replaceRange(
        open,
        close + 1,
        innerResult.toString(),
      );
    }
    
    expr = expr.replaceAll(Btn.multiply, "*");
    expr = expr.replaceAll(Btn.divide, "/");

    List<String> tokens = [];
    String current = "";

    // split into numbers + operators
    for (int i = 0; i < expr.length; i++) {
      String char = expr[i];

      // To restore: remove multi-line comment start indicator from line below 
      if ("+-*//*".contains(char)) {
        tokens.add(current);
        tokens.add(char);
        current = "";
      } else {
        current += char;
      }
    }

    tokens.add(current);

    // FIRST PASS: multiplication and division
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "*" || tokens[i] == "/") {
        double left = double.parse(tokens[i - 1]);
        double right = double.parse(tokens[i + 1]);

        double result =
            tokens[i] == "*"
                ? left * right
                : left / right;

        tokens.replaceRange(
          i - 1,
          i + 2,
          [result.toString()],
        );

        i--;
      }
    }

    // SECOND PASS: addition and subtraction
    double result = double.parse(tokens[0]);

    for (int i = 1; i < tokens.length; i += 2) {
      String op = tokens[i];
      double next = double.parse(tokens[i + 1]);

      if (op == "+") {
        result += next;
      } else {
        result -= next;
      }
    }

    return result;
    */
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
        promptMessage = "Try again";
      });
    }
  }

  // convert to percentage function
  void convertToPercentage(){
    // TODO: rewrite for expression-based calculator
    /*
    if(number1.isNotEmpty && operand.isNotEmpty && number2.isNotEmpty){
      // calculate before conversion
      calculate();
    }
    if(operand.isNotEmpty){
      // cant convert
      return;
    }
    
    final number = double.parse(number1);
    setState(() {
      number1="${(number / 100)}";
      operand = "";
      number2 = "";
    });*/
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

  // ##########
  Color getBtnColor(value){
    return [Btn.del, Btn.clr].contains(value)
        ?Colors.blueGrey
        :[
          Btn.per,
          Btn.multiply,
          Btn.add,
          Btn.subtract,
          Btn.divide,
          Btn.calculate,
        ].contains(value)
          ? Colors.orange
          : const Color.fromARGB(255, 47, 47, 47);
  }
}