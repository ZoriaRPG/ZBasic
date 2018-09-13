//Preliminary Expression Handler

int DoExpr(int word)
{
	int inistack = curstack;
	int buf[1024]; int q; bool foundop; bool sign;
	int number[14]; bool foundvalue; bool foundnum; bool foundvar;
	int len = SizeOfArray(word);
	int varid[4];
	for ( q = 0; q < len; ++q ) buf[q] = word[q];
	int place = 0;
	++q; buf[q] = 0; //terminate
	q = -1;
	while(reading)
	{
		++q;
		
		//look for numbers before an operator
		if ( !foundop && !foundvalue )
			//first value can be signed
		{
			if ( buf[q] == ' '; ) //eat WS
				continue;
			
			if ( buf[q] == '-' ) { sign = true; ++q; }
			//read the number portion of the string into a value.
			//numbers only
			
			while ( IsNumber(buf[q]) || buf[q] == '.' ) 
			{
				foundnum = true;
				if ( buf[q] == '.' ) 
				{
					if ( !dec )
					{
						dec = true;
						number[place] = buf[q]];
						++place;
					}
					else continue;
				}
				else
				{
					number[place] = buf[q];
					++place;
				}
			}
			
			if ( foundnum ) //it isn't a var, but a literal
			{
				if ( sign ) { sign = false; val = atof(number)*-1;  }//store the extracted value.
				else val = atof(number); //store the extracted value.
				foundvalue = true;
			}
			//variables
			if ( !foundnum ) //is it a variable?
			{
				bool seeking = true;
				while(seeking)
				{
					if ( buf[q] == 'I' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'N' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'L' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'E' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'F' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'C' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'W' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == 'S' ) { foundvar = true; seeking = false; break; }
					else if ( buf[q] == '<' ) { foundvar = true; seeking = false; break; }
					else break;
				}
				if ( foundvar ) //found it, so extract it.
				{
					for ( int w = q; w < q+2; ++w )
					{
						varid[w] = buf[q+w];
					}
					int vartype = ExtractVarType(varid);
					int indx = ExtractVarID(varid);
					val = GetVarValue(vartype,indx);
					foundvalue = true;
				}
					
			}
				
		}
		if ( foundvalue ) 
		//push value here
		stack.change(OPERAND);
		stack.push(val);
		
		// 1.2.3 A left parenthesis: push it onto the operator stack.
     
      
		//loop for a lparen
		if ( buf[q] == '(' ) 
		{
			//push the paren to operators
			stack.change(OPERATORS);
			stack.push('(');
		}
		
		//  1.2.4 A right parenthesis:
		if ( buf[q] == ')' ) 
		{
			/*
			1 While the thing on top of the operator stack is not a 
		   left parenthesis,
		     1 Pop the operator from the operator stack.
		     2 Pop the value stack twice, getting two operands.
		     3 Apply the operator to the operands, in the correct order.
		     4 Push the result onto the value stack.
		 2 Pop the left parenthesis from the operator stack, and discard it.
			*/
		}
		
		
		/*
		
	       1.2.5 An operator (call it thisOp):
		 1 While the operator stack is not empty, and the top thing on the
		   operator stack has the same or greater precedence as thisOp,
		   1 Pop the operator from the operator stack.
		//stack.change(OPERATOR);
		//stack.pop(INX1);
		   2 Pop the value stack twice, getting two operands.
		//
		// stack.change(OPERAND).
		// stack.pop(EXPR2);
		// stack.pop(EXPR1);
		   3 Apply the operator to the operands, in the correct order.
		   4 Push the result onto the value stack.
		//stack.push(EXPR2);
		 2 Push thisOp onto the operator stack.
	2. While the operator stack is not empty,
	    1 Pop the operator from the operator stack.
	    2 Pop the value stack twice, getting two operands.
	    3 Apply the operator to the operands, in the correct order.
	    4 Push the result onto the value stack.
	3. At this point the operator stack should be empty, and the value
	   stack should have only one value in it, which is the final result.
   */
		
		if ( !foundop && foundvalue )
			//the next thing must be an operator
		{
			if ( buf[q] == ' '; ) //eat WS
				continue;
			
			if ( IsOperator(buf[q] ) 
			{
				//push it and its precedence
				foundop = true;
			}
			
		}
	}
}