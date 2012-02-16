#include <hash_map>
#include <iostream>
#include <string>
#include <cmath>
#include <list>

using namespace __gnu_cxx;
using namespace std;

class tuple{
    public:
         const string &id;
         const int scope;
    tuple(const string &id,const int scope):id(id),scope(scope){}
    bool operator==(const tuple a) const{
        return id==a.id && scope==a.scope;
    }
	tuple operator=(const tuple& a){
		return tuple(a.id,a.scope);
	}
	
};

class TElement {
	public:
		virtual ~TElement(){};
};

class TType: public TElement {
	public:
		const unsigned long size;
		const bool basic;
		TType(unsigned long size,bool basic):size(size),basic(basic){};
};

class Field{
	public:
		TType* type;
		string& name;
		Field(TType* type,string& name):type(type),name(name){}
};

class TRegister: public TType{
	public:
		std::vector<Field*> fields;
		TRegister(unsigned long size,std::vector<Field*> fields):TType(size,false),fields(fields){}

};

class TUnion: public TType{
	public:
		std::vector<Field*> fields;
		TUnion(unsigned long size,std::vector<Field*> fields):TType(size,false),fields(fields){}

};


class TVar: public TElement{
	public:
		const TType& type;
		TVar(const TType type):type(type){}
};

class TFunc: public TElement{
	public:
		const TType& type;
		const std::vector<TType*> args;
		TFunc(TType& type, std::vector<TType*> args):type(type),args(args){}
};

class TArray: public TElement{
	public:
		const TType& type;
		const int length;
		TArray(TType& type, int length):type(type),length(length){}
};


/*
class idinfo{
    public:
        int attribute;
        string type;
        int size;
        union{
            float valuef;
            int valuei;
            char valuec;
            string * values;
            bool valueb;
        } ;
        VariableList * args;

    idinfo(){};
    idinfo(int attribute, string type, int size):attribute(attribute),type(type),size(size){}
    idinfo(int attribute, string type, int size, float valuef):attribute(attribute),type(type),size(size),valuef(valuef){}
    idinfo(int attribute, string type, int size, int valuei):attribute(attribute),type(type),size(size),valuef(valuei){}
    idinfo(int attribute, string type, int size, char valuec):attribute(attribute),type(type),size(size),valuef(valuec){}
    idinfo(int attribute, string type, int size, string * values):attribute(attribute),type(type),size(size),values(values){}
    idinfo(int attribute, string type, int size, bool valueb):attribute(attribute),type(type),size(size),valueb(valueb){}
    idinfo(int attribute, string type, int size, VariableList *args):attribute(attribute),type(type),size(size),args(args){}
    
};
*/
namespace __gnu_cxx{
    template<> class hash<tuple>{
        public:
            size_t operator()(const tuple &s) const { 
                int i;
                int sum=0;
                for(i=0; i<s.id.size(); i++){
                    sum=sum+s.id[i]*(int)(pow(31,s.id.size()-i+1));
                }
               // cout << sum+s.scope << endl;
                return sum+s.scope;
            }
    };
};


class Symtable {
	hash_map<tuple,TElement*> table;
	list<int> scopeStack;
	int scope;
    int nextscope;
	public:
		Symtable():scope(0){
			table[tuple(string("char"),scope)]=new TType(sizeof(char),true);
			table[tuple(string("integer"),scope)]=new TType(sizeof(int),true);
			table[tuple(string("float"),scope)]=new TType(sizeof(float),true);
			table[tuple(string("float"),scope)]=new TType(sizeof(bool),true);

		}
		
		
		int insert(string& name,TElement* elem){
			table[tuple(name,scope)]=elem;
		}

        int insrtnextscope(string& name, TElement* elem){
            table[tuple(name,scope+1)]=elem;
        }

		TElement* lookup(string name){
			tuple t(name,scope);
			hash_map<tuple,TElement*>::iterator it;
			it=table.find(t);
			if(it==table.end()){
				list<int>::iterator lit;
				for(lit = scopeStack.begin();lit!=scopeStack.end();lit++){
					t=tuple(name,*lit);
					it=table.find(t);
					if(!(it==table.end())){
						break;
					}
				}
			}
			if(it==table.end()){
				return NULL;
			}
			return it->second;
		}
        
        TType* lookupType(string name){
            tuple t(name,0);
            hash_map<tuple,TElement*>::iterator it;
            it=table.find(t);
            if(it==table.end()){
                return NULL;
            }
            return (TType *)it->second;
        }

        int begScope(){scopeStack.push_front(scope);scope=nextscope;nextscope++;}
        int endScope(){scope=scopeStack.front();scopeStack.pop_front();}
};
