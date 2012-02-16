#include <vector>
#include <iostream>
#include "symtable.h"

class NStatement;
class NExpression;
class NVariableDeclaration;

typedef std::vector<NStatement*> StatementList;
typedef std::vector<NExpression*> ExpressionList;
typedef std::vector<NVariableDeclaration*> VariableList;


class Node{
	public:
		virtual TType* typeChk(Symtable& t){return NULL;}
		virtual ~Node() {}
};

class NExpression : public Node {

};

class NLRExpression : public NExpression{
};

class NStatement : public Node {

};


class NExpressionStatement : public NStatement {
	public:
		NExpression &expr;
		NExpressionStatement(NExpression& expr):expr(expr){}
		TType* typeChk(Symtable& t ){
			return expr.typeChk(t);
		}
};

class NInteger : public NExpression {
	public :
		long long value;
		NInteger(long long value) : value(value) {}
		TType* typeChk(Symtable& t){
			return (TType*)t.lookupType("integer");
		}
};

class NDouble : public NExpression {
	public :
		double value;
		NDouble(double value) : value(value) {}
		TType* typeChk(Symtable& t){
			return (TType*)t.lookupType("double");
		}
};

class NString : public NExpression {
	public :
		std::string value;
		NString(const std::string &value) : value(value) {}
};

class NArray : public NExpression {
	public :
		ExpressionList values;
		NArray() { }
};

class NChar : public NExpression {
	public :
		char value;
		NChar(char value) : value(value){}
		TType* typeChk(Symtable& t){
			return (TType*)t.lookupType("char");
		}
};

class NBool : public NExpression {
	public:
		bool value;
		NBool(bool value) :value(value){}
		TType* typeChk(Symtable t){
			return (TType*)t.lookupType("boolean");
		}
};

class NIdentifier : public NLRExpression {
	public:
		std::string name;
		TType* type;
		NIdentifier(const std::string &name) : name(name){}
		NIdentifier(const std::string &name,TType* type) : name(name),type(type){}
		TType* typeChk(Symtable t){
			return type;
		}
};

class NArrayAccess : public NLRExpression{
	public:
		const NLRExpression &lexpr;
		NExpression &index;
		NArrayAccess(const NLRExpression &lexpr, NExpression &index):lexpr(lexpr),index(index){}
};

class NStructAccess : public NLRExpression{
	public:
		const NLRExpression &lexpr;
		NIdentifier &name;
		NStructAccess(const NLRExpression &lexpr,NIdentifier &name):lexpr(lexpr),name(name){}
};

class NFunctionCall : public NExpression {
	public:
		const NIdentifier &id;
		ExpressionList arguments;
		NFunctionCall(const NIdentifier &id, ExpressionList &arguments) : id(id), arguments(arguments){}
		TType* typeChk(Symtable &t){
			for(int i=0;i<arguments.size();i++){
				arguments[i]->typeChk(t);
			}
		}
};


class  NBinaryOperator : public NExpression {
	public :
		string op;
		NExpression &lexp;
		NExpression &rexp;
		NBinaryOperator(NExpression& lexp,string op,NExpression& rexp):op(op),lexp(lexp),rexp(rexp){}
		TType* typeChk(Symtable& t){
			TType* t1=lexp.typeChk(t);
			TType* t2=rexp.typeChk(t);
			if(isalpha(op[0])){
				if(t1->name=="boolean" && t2->name=="boolean"){
					return t1;
				}else{
					fprintf(stderr,"%s expected a boolean types but received %s and %s\n",op.c_str(),t1->name.c_str(),t2->name.c_str());
					/*should be NULL*/
					return t1;
				}
			}else{
				if(t1->numeric && t2->numeric){
					if(t1->name=="float") return t1;
					if(t2->name=="float") return t2;
					return t1;
				}else{
					fprintf(stderr,"%s expected a numeric types but received %s and %s\n",op.c_str(),t1->name.c_str(),t2->name.c_str());

					/*should be NULL*/
					if(t1->name=="float") return t1;
					if(t2->name=="float") return t2;
					return t1;
				}
			}
		}
};

class NUnaryOperator : public NExpression {
	public :
		string op;
		NExpression &rexp;
		NUnaryOperator(string op,NExpression& rexp):op(op),rexp(rexp){}
		TType* typeChk(Symtable& t){
			TType* t2=rexp.typeChk(t);
			if(isalpha(op[0])){
				if(t2->name=="boolean"){
					return t2;
				}else{
					fprintf(stderr,"%s expected a numeric type but received a %s\n",op.c_str(),t2->name.c_str());
					return NULL;
				}
			}else{
				if(t2->numeric){
					return t2;
				}else{
					fprintf(stderr,"%s expected a boolean and received a %s\n",op.c_str(),t2->name.c_str());
					return NULL;
				}
			}
		}
};

class NBlock: public NStatement{
	public :
		StatementList statements;
		NBlock() {};
		TType* typeChk(Symtable &t){
			for(int i=0;i<statements.size();i++){
				statements[i]->typeChk(t);
			}
            return NULL;
		}
};


class NVariableDeclaration : public NStatement {
	public:
		const NIdentifier& type;
		NIdentifier& id;
		NExpression *assigment;
		NVariableDeclaration(const NIdentifier& type, NIdentifier& id):type(type),id(id),assigment(NULL){}
		NVariableDeclaration(const NIdentifier& type,NIdentifier& id,NExpression* assignment):type(type),id(id),assigment(assigment){}
		TType* typeChk(Symtable &t){
			TType* t1 = t.lookupType(type.name);
			if(assigment!=NULL){
				TType* t2 = assigment->typeChk(t);
				if (t1->name!=t1->name){
					fprintf(stderr,"%s declared as %s but inicialized with %s\n",id.name.c_str(),t1->name.c_str(),t2->name.c_str());
					//return error
				}
				
			}
			return t1;
		}
};

class NFunctionDeclaration : public NStatement {
	public:
		const NIdentifier& type;
		const NIdentifier& id;
		VariableList args;
		NBlock &block;
		NFunctionDeclaration(const NIdentifier& type,const NIdentifier& id,const VariableList& args, NBlock block):type(type),id(id),args(args),block(block){}
		TType* typeChk(Symtable &t){
			for(int i=0;i<args.size();i++){
				args[i]->typeChk(t);
			}
			return block.typeChk(t);
		}
			
};

class NArrayDeclaration : public NStatement{
	public:
		const NIdentifier& id;
		const NIdentifier& type;
		ExpressionList elements;
		NArrayDeclaration(const NIdentifier& id, const NIdentifier& type, 
				ExpressionList& elements) :
			id(id), type(type), elements(elements){}
};

class NRegisterDeclaration : public NStatement{
	public:
		const NIdentifier& type;
		VariableList fields;
		NRegisterDeclaration(const NIdentifier& type, VariableList fields) :type(type), fields(fields){}
};

class NUnionDeclaration : public NStatement{
	public:
		const NIdentifier& type;
		VariableList fields;
		NUnionDeclaration(const NIdentifier& type, VariableList fields) : type(type), fields(fields){}
};


class NWhileDo : public NStatement{
	public:
		NExpression* cond;
		NBlock& block;
		NWhileDo(NExpression* cond, NBlock& block):cond(cond),block(block){}
		TType* typeChk(Symtable &t){
			cond->typeChk(t);	
			return block.typeChk(t);
		}
};

class NDoWhile : public NStatement{
	public:
		NExpression* cond;
		NBlock& block;
		NDoWhile(NExpression* cond, NBlock& block):cond(cond),block(block){}
		TType* typeChk(Symtable &t){
			cond->typeChk(t);	
			return block.typeChk(t);
		}
};

class NIf : public NStatement{
	public:
		NExpression& cond;
		NStatement& block;
		NStatement* elseBlock;
		NIf(NExpression& cond,NStatement& block):cond(cond),block(block){}
		NIf(NExpression& cond,NStatement& block, NStatement* elseBlock):cond(cond),block(block),elseBlock(elseBlock){}
		TType* typeChk(Symtable &t){
			cond.typeChk(t);
			if(elseBlock!=NULL) elseBlock->typeChk(t);
			return block.typeChk(t);
		}
};


class NFor : public NStatement{
	public:
		NIdentifier& id;
		NExpression* beg;
		NExpression* end;
		NIdentifier* array;
		NBlock& block;
		NFor(NIdentifier& id,NExpression* beg,NExpression* end,NBlock& block): id(id),beg(beg),end(end),block(block){};
		NFor(NIdentifier& id,NIdentifier* array,NBlock &block): id(id),array(array),block(block){};
		
};

class NStop : public NStatement{
};

class NNext : public NStatement{

};

class NReturn : public NStatement{
	public:
		const NExpression* expr;
		NReturn(){}
		NReturn(NExpression *expr):expr(expr){}
		
};

class NAssignment : public NStatement{
	public:
		const NLRExpression* var;
		NExpression* assig;
		NAssignment (const NLRExpression * var, NExpression *assigment):var(var),assig(assigment){}

};
