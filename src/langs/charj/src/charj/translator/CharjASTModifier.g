/**
 *  fill a description in
 */

tree grammar CharjASTModifier;

options {
    backtrack = true; 
    memoize = true;
    tokenVocab = Charj;
    ASTLabelType = CharjAST;
    output = AST;
}

@header {
package charj.translator;
}

@members {
    PackageScope currentPackage = null;
    ClassSymbol currentClass = null;
    MethodSymbol currentMethod = null;
    LocalScope currentLocalScope = null;
    Translator translator;

    AstModifier astmod = new AstModifier();
}

// Replace default ANTLR generated catch clauses with this action, allowing early failure.
@rulecatch {
    catch (RecognitionException re) {
        reportError(re);
        throw re;
    }
}


// Starting point for parsing a Charj file.
charjSource
    // TODO: go back to allowing multiple type definitions per file, check that
    // there is exactly one public type and return that one.
    :   ^(CHARJ_SOURCE 
        packageDeclaration?
        importDeclaration*
        readonlyDeclaration*
        typeDeclaration*)
    ;

packageDeclaration
    :   ^(PACKAGE (ids+=IDENT)+)  
    ;
    
importDeclaration
    :   ^(IMPORT qualifiedIdentifier '.*'?)
    ;

readonlyDeclaration
    :   ^(READONLY localVariableDeclaration)
    ;

typeDeclaration
@init {
    boolean array_type = false;
    astmod = new AstModifier();
}
    :   ^(TYPE (CLASS | (chareType | (chareArrayType { array_type = true; }))) IDENT
        (^('extends' parent=type))? (^('implements' type+))? classScopeDeclaration*)
        {
            $TYPE.tree.addChild(astmod.getPupRoutineNode());
            $TYPE.tree.addChild(astmod.getInitRoutineNode());
            $TYPE.tree.addChild(astmod.getCtorHelperNode());
            astmod.ensureDefaultCtor($TYPE.tree);
            if (array_type) astmod.ensureMigrationCtor($TYPE.tree);
        }
    |   ^(INTERFACE IDENT (^('extends' type+))?  interfaceScopeDeclaration*)
    |   ^(ENUM IDENT (^('implements' type+))? enumConstant+ classScopeDeclaration*)
    ;

chareArrayType
    :   ^(CHARE_ARRAY ARRAY_DIMENSION)
    ;

chareType
    :   CHARE
    |   GROUP
    |   NODEGROUP
    |   MAINCHARE
    ;

enumConstant
    :   ^(IDENT arguments?)
    ;
    
classScopeDeclaration
    :   ^(d=FUNCTION_METHOD_DECL m=modifierList? g=genericTypeParameterList? 
            ty=type IDENT f=formalParameterList a=domainExpression? 
            b=block?)
        {
            if($m.tree == null)
                astmod.fillPrivateModifier($d.tree);

            if(astmod.isEntry($d.tree))
                $d.tree.setType(CharjParser.ENTRY_FUNCTION_DECL, "ENTRY_FUNCTION_DECL");
        }
    |   ^(PRIMITIVE_VAR_DECLARATION m = modifierList? simpleType variableDeclaratorList)
        {
            if($m.tree == null)
                astmod.fillPrivateModifier($PRIMITIVE_VAR_DECLARATION.tree);
        }
    |   ^(OBJECT_VAR_DECLARATION m = modifierList? objectType variableDeclaratorList)
        {
            if($m.tree == null)
                astmod.fillPrivateModifier($OBJECT_VAR_DECLARATION.tree);
        }
    |   ^(cd=CONSTRUCTOR_DECL m=modifierList? g=genericTypeParameterList? IDENT f=formalParameterList 
            b=block)
        {
            if($m.tree == null)
                astmod.fillPrivateModifier($CONSTRUCTOR_DECL.tree);

            astmod.insertHelperRoutineCall($CONSTRUCTOR_DECL.tree);
            astmod.checkForDefaultCtor($CONSTRUCTOR_DECL, $CONSTRUCTOR_DECL.tree);
            astmod.checkForMigrationCtor($CONSTRUCTOR_DECL);

            if(astmod.isEntry($CONSTRUCTOR_DECL.tree))
                $CONSTRUCTOR_DECL.tree.setType(CharjParser.ENTRY_CONSTRUCTOR_DECL, "ENTRY_CONSTRUCTOR_DECL");
        }
    ;
    
interfaceScopeDeclaration
    :   ^(FUNCTION_METHOD_DECL modifierList? genericTypeParameterList? 
            type IDENT formalParameterList domainExpression?)
        // Interface constant declarations have been switched to variable
        // declarations by Charj.g; the parser has already checked that
        // there's an obligatory initializer.
    |   ^(PRIMITIVE_VAR_DECLARATION modifierList? simpleType variableDeclaratorList)
    |   ^(OBJECT_VAR_DECLARATION modifierList? objectType variableDeclaratorList)
    ;

variableDeclaratorList
    :   ^(VAR_DECLARATOR_LIST variableDeclarator+)
    ;

variableDeclarator
    :   ^(VAR_DECLARATOR variableDeclaratorId variableInitializer?)
        {
            astmod.dealWithInit($VAR_DECLARATOR);
        }
    ;
    
variableDeclaratorId
    :   ^(IDENT domainExpression?)
        {
            if (!($IDENT.hasParentOfType(CharjParser.READONLY))) astmod.varPup($IDENT);
        }
    ;

variableInitializer
    :   arrayInitializer
    |   expression
    ;

arrayInitializer
    :   ^(ARRAY_INITIALIZER variableInitializer*)
    ;

templateArg
    : genericTypeArgument
    | literal
    ;

templateArgList
    :   templateArg (','! templateArg)*
    ;

templateInstantiation
    :    ^(TEMPLATE_INST templateArgList)
    |    ^(TEMPLATE_INST templateInstantiation)
    ;

genericTypeParameterList
    :   ^(GENERIC_TYPE_PARAM_LIST genericTypeParameter+)
    ;

genericTypeParameter
    :   ^(IDENT bound?)
    ;
        
bound
    :   ^(EXTENDS_BOUND_LIST type+)
    ;

modifierList
    :   ^(MODIFIER_LIST modifier+)
        {
            astmod.arrangeModifiers($MODIFIER_LIST.tree);
        }
    ;

modifier
    :   PUBLIC
    |   PRIVATE
    |   PROTECTED
    |   ENTRY
    |   ABSTRACT
    |   NATIVE
    |   localModifier
    ;

localModifierList
    :   ^(LOCAL_MODIFIER_LIST localModifier+)
    ;

localModifier
    :   FINAL
    |   STATIC
    |   VOLATILE
    ;

type
    :   simpleType
    |   objectType 
    |   VOID
    ;

simpleType
    :   ^(SIMPLE_TYPE primitiveType domainExpression?)
    ;
    
objectType
    :   ^(OBJECT_TYPE qualifiedTypeIdent domainExpression?)
    |   ^(PROXY_TYPE qualifiedTypeIdent domainExpression?)
    |   ^(REFERENCE_TYPE qualifiedTypeIdent domainExpression?)
    |   ^(POINTER_TYPE qualifiedTypeIdent domainExpression?)
        {
            astmod.dealWithEntryMethodParam($POINTER_TYPE, $POINTER_TYPE.tree);
        }
    ;

qualifiedTypeIdent
    :   ^(QUALIFIED_TYPE_IDENT typeIdent+) 
    ;

typeIdent
    :   ^(IDENT templateInstantiation?)
    ;

primitiveType
    :   BOOLEAN
    |   CHAR
    |   BYTE
    |   SHORT
    |   INT
    |   LONG
    |   FLOAT
    |   DOUBLE
    ;

genericTypeArgumentList
    :   ^(GENERIC_TYPE_ARG_LIST genericTypeArgument+)
    ;
    
genericTypeArgument
    :   type
    |   '?'
    ;

formalParameterList
    :   ^(FORMAL_PARAM_LIST formalParameterStandardDecl* formalParameterVarargDecl?) 
    ;
    
formalParameterStandardDecl
    :   ^(FORMAL_PARAM_STD_DECL localModifierList? type variableDeclaratorId)
    ;
    
formalParameterVarargDecl
    :   ^(FORMAL_PARAM_VARARG_DECL localModifierList? type variableDeclaratorId)
    ;
    
// FIXME: is this rule right? Verify that this is ok, I expected something like:
// IDENT (^(DOT qualifiedIdentifier IDENT))*
qualifiedIdentifier
    :   IDENT
    |   ^(DOT qualifiedIdentifier IDENT)
    ;
    
block
    :   ^(BLOCK (blockStatement)*)
    ;
    
blockStatement
    :   localVariableDeclaration
    |   statement
    ;
    
localVariableDeclaration
    :   ^(PRIMITIVE_VAR_DECLARATION localModifierList? simpleType variableDeclaratorList)
    |   ^(OBJECT_VAR_DECLARATION localModifierList? objectType variableDeclaratorList)
    ;

statement
    :   nonBlockStatement
    |   block
    ;

nonBlockStatement
    :   ^(ASSERT expression expression?)
    |   ^(IF parenthesizedExpression block block?)
    |   ^(FOR forInit? FOR_EXPR expression? FOR_UPDATE expression* block)
    |   ^(FOR_EACH localModifierList? type IDENT expression block) 
    |   ^(WHILE parenthesizedExpression block)
    |   ^(DO block parenthesizedExpression)
    |   ^(SWITCH parenthesizedExpression switchCaseLabel*)
    |   ^(RETURN expression?)
    |   ^(THROW expression)
    |   ^(BREAK IDENT?) {
            if ($IDENT != null) {
                translator.error(this, "Labeled break not supported yet, ignoring.", $IDENT);
            }
        }
    |   ^(CONTINUE IDENT?) {
            if ($IDENT != null) {
                translator.error(this, "Labeled continue not supported yet, ignoring.", $IDENT);
            }
        }
    |   ^(LABELED_STATEMENT IDENT statement)
    |   expression
    |   ^('delete' expression)
    |   ^(EMBED STRING_LITERAL EMBED_BLOCK)
    |   ';' // Empty statement.
    |   ^(PRINT expression*)
    |   ^(PRINTLN expression*)
    |   ^(EXIT expression?)
    |   EXITALL
    ;
        
switchCaseLabel
    :   ^(CASE expression blockStatement*)
    |   ^(DEFAULT blockStatement*)
    ;
    
forInit
    :   localVariableDeclaration 
    |   expression+
    ;
    
// EXPRESSIONS

parenthesizedExpression
    :   ^(PAREN_EXPR expression)
    ;
    
expression
    :   ^(EXPR expr)
    ;

expr
    :   ^(ASSIGNMENT expr expr)
    |   ^(PLUS_EQUALS expr expr)
    |   ^(MINUS_EQUALS expr expr)
    |   ^(TIMES_EQUALS expr expr)
    |   ^(DIVIDE_EQUALS expr expr)
    |   ^(AND_EQUALS expr expr)
    |   ^(OR_EQUALS expr expr)
    |   ^(POWER_EQUALS expr expr)
    |   ^(MOD_EQUALS expr expr)
    |   ^('>>>=' expr expr)
    |   ^('>>=' expr expr)
    |   ^('<<=' expr expr)
    |   ^('?' expr expr expr)
    |   ^(OR expr expr)
    |   ^(AND expr expr)
    |   ^(BITWISE_OR expr expr)
    |   ^(POWER expr expr)
    |   ^(BITWISE_AND expr expr)
    |   ^(EQUALS expr expr)
    |   ^(NOT_EQUALS expr expr)
    |   ^(INSTANCEOF expr type)
    |   ^(LTE expr expr)
    |   ^(GTE expr expr)
    |   ^('>>>' expr expr)
    |   ^('>>' expr expr)
    |   ^(GT expr expr)
    |   ^('<<' expr expr)
    |   ^(LT expr expr)
    |   ^(PLUS expr expr)
    |   ^(MINUS expr expr)
    |   ^(TIMES expr expr)
    |   ^(DIVIDE expr expr)
    |   ^(MOD expr expr)
    |   ^(UNARY_PLUS expr)
    |   ^(UNARY_MINUS expr)
    |   ^(PRE_INC expr)
    |   ^(PRE_DEC expr)
    |   ^(POST_INC expr)
    |   ^(POST_DEC expr)
    |   ^(TILDE expr)
    |   ^(NOT expr)
    |   ^(CAST_EXPR type expr)
    |   primaryExpression
    ;
    
primaryExpression
    :   ^(DOT primaryExpression
                (   IDENT
                |   THIS
                |   SUPER
                )
        )
        ->   ^(ARROW primaryExpression
                   IDENT?
                   THIS?
                   SUPER?
             )
    |   parenthesizedExpression
    |   IDENT
    |   ^(METHOD_CALL primaryExpression genericTypeArgumentList? arguments)
    |   ^(ENTRY_METHOD_CALL ^(AT primaryExpression IDENT) genericTypeArgumentList? arguments)
        ->  ^(ENTRY_METHOD_CALL ^(DOT primaryExpression IDENT) genericTypeArgumentList? arguments)
    |   explicitConstructorCall
    |   ^(ARRAY_ELEMENT_ACCESS primaryExpression expression)
    |   literal
    |   newExpression
    |   THIS
    |   arrayTypeDeclarator
    |   SUPER
    |   GETNUMPES
    |   GETNUMNODES
    |   GETMYPE
    |   GETMYNODE
    |   GETMYRANK
    ;
    
explicitConstructorCall
    :   ^(THIS_CONSTRUCTOR_CALL genericTypeArgumentList? arguments)
    |   ^(SUPER_CONSTRUCTOR_CALL primaryExpression? genericTypeArgumentList? arguments)
    ;

arrayTypeDeclarator
    :   ^(ARRAY_DECLARATOR (arrayTypeDeclarator | qualifiedIdentifier | primitiveType))
    ;

newExpression
    :   ^(NEW_EXPRESSION arguments? domainExpression)
    |   ^(NEW type arguments)
    ;

arguments
    :   ^(ARGUMENT_LIST expression*)
    ;

literal 
    :   HEX_LITERAL
    |   OCTAL_LITERAL
    |   DECIMAL_LITERAL
    |   FLOATING_POINT_LITERAL
    |   CHARACTER_LITERAL
    |   STRING_LITERAL          
    |   TRUE
    |   FALSE
    |   NULL
    ;

rangeItem
    :   DECIMAL_LITERAL
    |   IDENT
    ;

rangeExpression
    :   ^(RANGE_EXPRESSION rangeItem)
    |   ^(RANGE_EXPRESSION rangeItem rangeItem)
    |   ^(RANGE_EXPRESSION rangeItem rangeItem rangeItem)
    ;

rangeList
    :   rangeExpression (','! rangeExpression)*
    ;

domainExpression
    :   ^(DOMAIN_EXPRESSION rangeList)
    ;