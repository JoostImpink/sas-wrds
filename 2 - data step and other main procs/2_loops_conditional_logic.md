# Conditional code and loops

## Conditional code: `IF-THEN-ELSE` <a name="ifthenelse"></a>

Yes, in SAS, you can use **conditional logic** similar to other programming languages with **`IF-THEN`**, **`ELSE IF-THEN`**, and **`ELSE`** statements to control the flow of your program.

### Syntax:
```sas
IF condition1 THEN action1;
ELSE IF condition2 THEN action2;
ELSE action3;
```

### Explanation:
- **`IF-THEN`**: Executes the specified action if the condition is true.
- **`ELSE IF-THEN`**: Provides additional conditions to check if the previous `IF` or `ELSE IF` conditions were false.
- **`ELSE`**: Executes the action if all previous conditions are false.

### Example:
```sas
DATA b_comp;
SET a_comp;
    /* define the length of variable type */
    length type $10;
    
    IF sale >= 300 THEN type = 'Enterprise';
    ELSE IF sale >= 100 THEN type = 'Large';
    ELSE IF sale >= 50 THEN type = 'Medium';
    ELSE type = 'Small';
RUN;
```

SAS evaluates conditions **sequentially**. Once it finds a true condition, it skips the remaining conditions in that block. You can use **multiple `IF-THEN`** statements without `ELSE IF`, but using `ELSE IF` improves efficiency when checking mutually exclusive conditions.


## Conditional code: `SELECT-WHEN` <a name="selectwhen"></a>

In addition to IF-THEN-ELSE, SAS also supports **`SELECT-WHEN`** statements, which work like a switch-case structure for more complex conditional logic. It allows you to test multiple conditions and execute corresponding actions, making it useful when you have multiple mutually exclusive conditions to check.

### Syntax:
```sas
SELECT;
    WHEN (condition1) action1;
    WHEN (condition2) action2;
    OTHERWISE action3;
END;
```

The `SELECT` statement starts the conditional block, `WHEN` specifies conditions to test and executes the corresponding action if true, `OTHERWISE` provides a default action if no conditions are met, and `END` closes the `SELECT` block.

### Example:
```sas
DATA employee_status;
    SET employees;

    SELECT;
        WHEN (age >= 65) status = 'Retired';
        WHEN (age >= 18 AND age < 65) status = 'Active';
        OTHERWISE status = 'Minor';
    END;
RUN;
```

### Complex Example:

Let's create a variable using the Boston Consulting Group Matrix where which classifies products into four categories:

1. **Star**: High market growth and high market share.
2. **Cash Cow**: Low market growth but high market share.
3. **Question Mark**: High market growth but low market share.
4. **Dog**: Low market growth and low market share.

We would need aggregates to measure market share, so for now let's use sales as a proxy for market share (not the best proxy), and the percentage growth in sales as a measure of growth:

```sas
data b_comp (where =(growth ne .)); /* filter on output dataset: only obs where growth is calculated */
set a_comp (where = (sale > 0)); /* filter on input dataset to drop obs where sale is 0 or missing */
by gvkey;
retain sale_prev;
/* for the first row of each gvkey set sale_prev to missing */
if first.gvkey then sale_prev = .;
/* calculate growth; it will be missing for each first year */
growth = sale / sale_prev - 1;
/* set sale_prev so it can be used in the next record */
sale_prev = sale;
run;
```

Using `SELECT-CASE` to classify Compustat firms:

```sas
DATA c_classification;
SET b_comp;

SELECT;
	/* Star: High sales (market share) and high growth */
	WHEN (sale > 100 AND growth > 0.05) DO;
		status = 'Star';
	END;

	/* Cash Cow: High sales (market share) and low growth */
	WHEN (sale > 100 AND growth <= 0.05) DO;
		status = 'Cash Cow';
	END;

	/* Question Mark: Low sales (market share) but high growth */
	WHEN (sale <= 100 AND growth > 0.05) DO;
		status = 'Question Mark';
	END;

	/* Dog: Low sales (market share) and low growth */
	OTHERWISE DO;
		status = 'Dog';
	END;
END;
RUN;
```

## Loops <a name="loops"></a>

SAS provides several mechanisms for implementing loops. Loops can be within a **DATA step** (this document) or using **macro code** (see macro code). 

### **DO Loops (DATA Step)**
The `DO` loop in a DATA step is used for repetitive execution of a block of code. There are three main types of `DO` loops in the DATA step:

#### a. **Simple Iterative DO Loop**
Executes a block of code a specified number of times.

```sas
DATA example;
    DO i = 1 TO 10;
        total = i * 5;
        OUTPUT;
    END;
RUN;
```
- This loop runs from `i = 1` to `i = 10`, multiplying each value by 5 and storing it in the `total` variable.
- The `OUTPUT` statement writes the result for each iteration to the dataset.

#### b. **DO UNTIL Loop**
Executes the block of code until a specified condition becomes **true**.

```sas
DATA example;
    x = 0;
    DO UNTIL (x >= 50);
        x + 5;
        OUTPUT;
    END;
RUN;
```
- The loop continues until `x >= 50` becomes true.
- `x + 5` is a shorthand way to increment `x` by 5 on each iteration.

#### c. **DO WHILE Loop**
Executes the block of code **while** a specified condition remains **true**.

```sas
DATA example;
    x = 1;
    DO WHILE (x < 20);
        x = x * 2;
        OUTPUT;
    END;
RUN;
```
- The loop continues as long as `x < 20`. On each iteration, `x` is doubled.


### Summary of Loop Types in SAS:

| Loop Type        | Syntax                  | Executes While | Common Usage                              |
|------------------|-------------------------|----------------|-------------------------------------------|
| **DO**           | `DO i = start TO end;`   | Counter-based  | Repeated processing with a fixed range.   |
| **DO UNTIL**     | `DO UNTIL(condition);`   | False          | Exit loop once condition becomes true.    |
| **DO WHILE**     | `DO WHILE(condition);`   | True           | Continue while condition is true.         |

### Nested loops

To repeat/loop over values, use the 'do' loop:

```SAS
data randomSales;
do id = 1 to 100;
   do year = 1 to 10;
	   x = 2010 + year;
	   u = rand("Uniform"); /* generates a random number between 0 and 1 from a uniform distribution */
	   sales =  100 * u;  /* scales the random number to a range between 0 and 100 */
	   output; /* writes a new record for each iteration */
   end; /* end of year loop */	  
end; /* end of id loop */
run;
```

In this example, two nested loops generate a dataset with 100 randomly generated firms, each with 10 years of data. The `output` statement ensures that a new record is written to the dataset for each combination of `id` and `year`. Without the `output` statement, only the final iteration (where `id` is 100 and `year` is 20) would be saved.



