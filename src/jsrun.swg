/* -----------------------------------------------------------------------------
 * javascriptrun.swg
 *
 * This file contains the runtime support for Duktape modules
 * and includes code for managing global variables and pointer
 * type checking.
 * ----------------------------------------------------------------------------- */

#ifdef __cplusplus
extern "C" {
#endif

#if !defined(SWIG_DUK_TARGET)
#error SWIG_DUK_TARGET not defined
#endif

/* -----------------------------------------------------------------------------
 * global swig types
 * ----------------------------------------------------------------------------- */
/* Constant table */
#define SWIG_DUK_INT     1
#define SWIG_DUK_FLOAT   2
#define SWIG_DUK_STRING  3
#define SWIG_DUK_POINTER 4
#define SWIG_DUK_BINARY  5
#define SWIG_DUK_CHAR    6

/* Structure for variable linking table */
typedef struct {
  const char *name;
  duk_idx_t get;
  duk_idx_t set;
} SWIG_duk_var_info;

//typedef dukL_Reg SWIG_duk_method;

/* Constant information structure */
typedef struct {
    int type;
    char *name;
    long lvalue;
    double dvalue;
    void *pvalue;
    SWIG_type_info **ptype;
} SWIG_duk_const_info;

#endif

typedef struct {
  const char *name;
  duk_c_function getmethod;
  duk_c_function setmethod;
} SWIG_duk_property;


struct SWIG_duk_class;
/* Can be used to create namespaces. Currently used to wrap class static methods/variables/constants */
typedef struct SWIG_duk_namespace {
  const char            *name;
  SWIG_duk_method       *ns_methods;
  SWIG_duk_attribute    *ns_attributes;
  SWIG_duk_const_info   *ns_constants;
  struct SWIG_duk_class        **ns_classes;
  struct SWIG_duk_namespace    **ns_namespaces;
} SWIG_duk_namespace;

typedef struct SWIG_duk_class {
  const char    *name; /* Name that this class has in Duktape */
  const char    *fqname; /* Fully qualified name - Scope + class name */
  SWIG_type_info   **type;
  duk_CFunction  constructor;
  void    (*destructor)(void *);
  SWIG_duk_method   *methods;
  SWIG_duk_attribute     *attributes;
  SWIG_duk_namespace    *cls_static;
  SWIG_duk_method   *prototype; /* 0 for -edukc */
  struct SWIG_duk_class **bases;
  const char **base_names;
} SWIG_duk_class;

/* this is the struct for wrapping all pointers in SwigDuk
*/
typedef struct {
  SWIG_type_info   *type;
  int own;  /* 1 if owned & must be destroyed */
  void *ptr;
} SWIG_duk_userdata;

/* this is the struct for wrapping arbitrary packed binary data
(currently it is only used for member function pointers)
the data ordering is similar to SWIG_duk_userdata, but it is currently not possible
to tell the two structures apart within SWIG, other than by looking at the type
*/
typedef struct {
  SWIG_type_info   *type;
  int     own;  /* 1 if owned & must be destroyed */
  char data[1];       /* arbitary amount of data */    
} SWIG_duk_rawdata;

/* Common SWIG API */
#define SWIG_NewPointerObj(ctx, ptr, type, owner)       SWIG_Duk_NewPointerObj(ctx, (void *)ptr, type, owner)
#define SWIG_ConvertPtr(ctx,idx, ptr, type, flags)    SWIG_Duk_ConvertPtr(ctx,idx,ptr,type,flags)
#define SWIG_MustGetPtr(ctx,idx, type,flags, argnum,fnname)  SWIG_Duk_MustGetPtr(ctx,idx, type,flags, argnum,fnname)
/* for C++ member pointers, ie, member methods */
#define SWIG_ConvertMember(ctx, idx, ptr, sz, ty)       SWIG_Duk_ConvertPacked(ctx, idx, ptr, sz, ty)
#define SWIG_NewMemberObj(ctx, ptr, sz, type)      SWIG_Duk_NewPackedObj(ctx, ptr, sz, type)

/* Runtime API */
#define SWIG_GetModule(clientdata) SWIG_duk_GetModule((duk_context*)(clientdata))
#define SWIG_SetModule(clientdata, pointer) SWIG_duk_SetModule((duk_context*)(clientdata), pointer)
#define SWIG_MODULE_CLIENTDATA_TYPE duk_context*

/* helper #defines */
#define SWIG_fail {goto fail;}
#define SWIG_fail_arg(func_name,argnum,type) \
  {SWIG_duk_pushferrstring(ctx,"Error in %s (arg %d), expected '%s' got '%s'",\
  func_name,argnum,type,SWIG_duk_typename(ctx,argnum));\
  goto fail;}
#define SWIG_fail_ptr(func_name,argnum,type) \
  SWIG_fail_arg(func_name,argnum,(type && type->str)?type->str:"void*")
#define SWIG_check_num_args(func_name,a,b) \
  if (duk_get_top(ctx)<a || duk_get_top(ctx)>b) \
  {SWIG_duk_pushferrstring(ctx,"Error in %s expected %d..%d args, got %d",func_name,a,b,duk_get_top(ctx));\
  goto fail;}

#define SWIG_duk_add_function(ctx,n,f) \
  duk_push_c_function(ctx, f), \
  duk_push_string(ctx, n)


#define SWIG_duk_add_boolean(ctx,n,b) \
  duk_push_boolean(ctx, b), \
  duk_push_string(ctx, n)
  // FIXME duk_rawset(ctx,-3))

/* special helper for allowing 'undefined' for usertypes */
#define SWIG_isptrtype(ctx,I) (duk_is_pointer(ctx,I) || duk_is_undefined(ctx,I))

#ifdef __cplusplus
/* Special helper for member function pointers 
it gets the address, casts it, then dereferences it */
/*#define SWIG_mem_fn_as_voidptr(a)  (*((char**)&(a))) */
#endif

/* storing/access of SWIG_module_info */
SWIGRUNTIME SWIG_module_info *
SWIG_duk_get_module(duk_context *ctx) {
  SWIG_module_info *ret = 0;
  duk_push_string(ctx,"SWIG_runtime_data_type_pointer" SWIG_RUNTIME_VERSION SWIG_TYPE_TABLE_NAME);
  duk_rawget(ctx,LUA_REGISTRYINDEX);
  if (duk_is_pointer(ctx,-1))
    ret=(SWIG_module_info*)duk_get_pointer(ctx,-1);
  duk_pop_n(ctx,1);  /* tidy */
  return ret;
}

SWIGRUNTIME void
SWIG_duk_set_module(duk_context *ctx, SWIG_module_info *module) {
  /* add this all into the Duktape global stash */
  duk_push_global_stash(ctx);
  duk_push_pointer(ctx,(void *)module);
  duk_push_string(ctx,"SWIG_runtime_data_type_pointer" SWIG_RUNTIME_VERSION SWIG_TYPE_TABLE_NAME);
}

/* -----------------------------------------------------------------------------
 * global variable support code
 * ----------------------------------------------------------------------------- */

SWIGINTERN int SWIG_duk_namespace_get(duk_context *ctx)
{
/*  there should be 2 params passed in
  (1) table (not the meta table)
  (2) string name of the attribute
*/
  assert(duk_is_object(ctx,-2));  /* just in case */
  duk_get_prototype(ctx,-2);
  assert(duk_is_object(ctx,-1));
  SWIG_duk_get_table(ctx,".get"); /* find the .get table */
  assert(duk_is_object(ctx,-1));
  /* look for the key in the .get table */
  duk_pushvalue(ctx,2);  /* key */
  duk_rawget(ctx,-2);
  duk_remove(ctx,-2); /* stack tidy, remove .get table */
  if (duk_is_c_function(ctx,-1))
  {  /* found it so call the fn & return its value */
    duk_call(ctx,0,1);  /* 1 value in (userdata),1 out (result) */
    duk_remove(ctx,-2); /* stack tidy, remove prototype */
    return 1;
  }
  duk_pop_n(ctx,1);  /* remove whatever was there */
  /* ok, so try the .fn table */
  SWIG_duk_get_table(ctx,".fn"); /* find the .get table */
  assert(duk_is_object(ctx,-1));  /* just in case */
  duk_pushvalue(ctx,2);  /* key */
  duk_rawget(ctx,-2);  /* look for the fn */
  duk_remove(ctx,-2); /* stack tidy, remove .fn table */
  if (duk_isfunction(ctx,-1)) /* note: whether it's a C function or JS function */
  {  /* found it so return the fn & let duk call it */
    duk_remove(ctx,-2); /* stack tidy, remove prototype */
    return 1;
  }
  duk_pop_n(ctx,1);  /* remove whatever was there */
  return 0;
}

SWIGINTERN int SWIG_duk_namespace_set(duk_context *ctx)
{
/*  there should be 3 params passed in
  (1) table (not the meta table)
  (2) string name of the attribute
  (3) any for the new value
*/

  assert(duk_is_object(ctx,1));
  duk_get_prototype(ctx,1);    /* get the meta table */
  assert(duk_is_object(ctx,-1));

  SWIG_duk_get_table(ctx,".set"); /* find the .set table */
  if (duk_is_object(ctx,-1))
  {
    /* look for the key in the .set table */
    duk_pushvalue(ctx,2);  /* key */
    duk_rawget(ctx,-2);
    if (duk_iscfunction(ctx,-1))
    {  /* found it so call the fn & return its value */
      duk_pushvalue(ctx,3);  /* value */
      duk_call(ctx,1,0);
      return 0;
    }
    duk_pop_n(ctx,1);  /* remove the value */
  }
  duk_pop_n(ctx,1);  /* remove the value .set table */
  duk_pop_n(ctx,1); /* remote prototype */
  // FIXME duk_rawset(ctx,-3);
  return 0;
}

SWIGINTERN void SWIG_duk_InstallConstants(duk_context *ctx, SWIG_duk_const_info constants[]); /* forward declaration */
SWIGINTERN void  SWIG_duk_add_variable(duk_context *ctx,const char *name,duk_CFunction getFn,duk_CFunction setFn); /* forward declaration */
SWIGINTERN void  SWIG_duk_class_register(duk_context *ctx,SWIG_duk_class *clss);

/* helper function - register namespace methods and attributes into namespace */
SWIGINTERN int SWIG_duk_add_namespace_details(duk_context *ctx, SWIG_duk_namespace *ns)
{
  int i;
  /* There must be namespace table (not prototype) at the top of the stack */
  assert(duk_is_object(ctx,-1));
  SWIG_duk_InstallConstants(ctx, ns->ns_constants);

  /* add methods to the namespace/module table */
  for(i=0;ns->ns_methods[i].name;i++){
    SWIG_duk_add_function(ctx,ns->ns_methods[i].name,ns->ns_methods[i].func);
  }
  duk_get_prototype(ctx,-1);

  /* add fns */
  for(i=0;ns->ns_attributes[i].name;i++){
    SWIG_duk_add_variable(ctx,ns->ns_attributes[i].name,ns->ns_attributes[i].getmethod,ns->ns_attributes[i].setmethod);
  }

  /* clear stack - remove metatble */
  duk_pop_n(ctx,1);
  return 0;
}

/* Register all classes in the namespace */
SWIGINTERN void SWIG_duk_add_namespace_classes(duk_context *ctx, SWIG_duk_namespace *ns)
{
  SWIG_duk_class **classes;

  /* There must be a module/namespace table at the top of the stack */
  assert(duk_is_object(ctx,-1));

  classes = ns->ns_classes;

  if( classes != 0 ) {
    while(*classes != 0) {
      SWIG_duk_class_register(ctx, *classes);
      classes++;
    }
  }
}


/* -----------------------------------------------------------------------------
 * global variable support code: classes
 * ----------------------------------------------------------------------------- */

SWIGINTERN void  SWIG_duk_get_class_prototype(duk_context *ctx,const char *cname);

typedef int (*SWIG_duk_base_iterator_func)(duk_State*,SWIG_type_info*, int, int *ret);

SWIGINTERN int SWIG_duk_iterate_bases(duk_context *ctx, SWIG_type_info * SWIGUNUSED SWIG_type,
  int first_arg, SWIG_duk_base_iterator_func func, int  *const ret)
{
    /* first_arg - position of the object in stack. Everything that is above are arguments
     * and is passed to every evocation of the func */
    int last_arg = duk_get_top(ctx);/* position of last argument */
    int original_prototype = last_arg + 1;
    size_t bases_count;
    int result = SWIG_ERROR;
    int bases_table;
    (void)SWIG_type;
    duk_get_prototype(ctx,first_arg);

    /* initialise base search */
    SWIG_duk_get_table(ctx,".bases");
    assert(duk_is_object(ctx,-1));
    bases_count = duk_rawlen(ctx,-1);
    bases_table = duk_get_top(ctx);

    if(ret)
      *ret = 0;
    if(bases_count>0)
    {
      int to_remove;
      size_t i;
      int j;
      int subcall_last_arg;
      int subcall_first_arg = duk_get_top(ctx) + 1;/* Here a copy of first_arg and arguments begin */
      int valid = 1;
      SWIG_type_info *base_SWIG_type = 0;
      for(j=first_arg;j<=last_arg;j++)
        duk_pushvalue(ctx,j);
      subcall_last_arg = duk_get_top(ctx);

      /* Trick: temporarily replacing original prototype with prototype for base class and call getter */
      for(i=0;i<bases_count;i++) {
        /* Iteration through class bases */
        duk_rawgeti(ctx,bases_table,i+1);
        base_SWIG_type = 0;
        if(duk_is_undefined(ctx,-1)) {
          valid = 0;
          duk_pop_n(ctx,1);
        } else {
          valid = 1;
        }

        if(!valid)
          continue;
        assert(duk_is_pointer(ctx, subcall_first_arg));
        assert(duk_is_object(ctx,-1));
        duk_setprototype(ctx,subcall_first_arg); /* Set new prototype */
        assert(duk_get_top(ctx) == subcall_last_arg);
        result = func(ctx, base_SWIG_type,subcall_first_arg, ret); /* Forward call */
        if(result != SWIG_ERROR) {
          break;
        }
      }
      /* Restore original prototype */
      duk_pushvalue(ctx,original_prototype);
      duk_setprototype(ctx,first_arg);
      /* Clear - remove everything between last_arg and subcall_last_arg including */
      to_remove = subcall_last_arg - last_arg;
      for(j=0;j<to_remove;j++)
        duk_remove(ctx,last_arg+1);
    } else {
      /* Remove everything after last_arg */
      duk_pop_n(ctx, duk_get_top(ctx) - last_arg);
    }
    if(ret) assert(duk_get_top(ctx) == last_arg + *ret);
    return result;
}

/* The class.get method helper, performs the lookup of class attributes.
 * It returns an error code. Number of function return values is passed inside 'ret'.
 * first_arg is not used in this function because function always has 2 arguments.
 */
SWIGINTERN int  SWIG_duk_class_do_get_item(duk_context *ctx, SWIG_type_info *type, int SWIGUNUSED first_arg, int *ret)
{
/*  there should be 2 params passed in
  (1) userdata (not the meta table)
  (2) string name of the attribute
*/
  int bases_search_result;
  int substack_start = duk_get_top(ctx)-2;
  assert(first_arg == substack_start+1);
  duk_checkstack(ctx,5);
  assert(duk_isuserdata(ctx,-2));  /* just in case */
  duk_getprototype(ctx,-2);    /* get the meta table */
  assert(duk_is_object(ctx,-1));  /* just in case */
  /* NEW: looks for the __getitem() fn
  this is a user provided get fn */
  SWIG_duk_get_table(ctx,"__getitem"); /* find the __getitem fn */
  if (duk_iscfunction(ctx,-1))  /* if its there */
  {  /* found it so call the fn & return its value */
    duk_pushvalue(ctx,substack_start+1);  /* the userdata */
    duk_pushvalue(ctx,substack_start+2);  /* the parameter */
    duk_call(ctx,2,1);  /* 2 value in (userdata),1 out (result) */
    duk_remove(ctx,-2); /* stack tidy, remove prototype */
    if(ret) *ret = 1;
    return SWIG_OK;
  }
  duk_pop_n(ctx,1);
  /* Remove the prototype */
  duk_pop_n(ctx,1);
  /* Search in base classes */
  bases_search_result = SWIG_duk_iterate_bases(ctx,type,substack_start+1,SWIG_duk_class_do_get_item,ret);
  return bases_search_result;  /* sorry not known */
}


/* The class.get method helper, performs the lookup of class attributes.
 * It returns an error code. Number of function return values is passed inside 'ret'.
 * first_arg is not used in this function because function always has 2 arguments.
 */
SWIGINTERN int SWIG_duk_class_do_get(duk_context *ctx, SWIG_type_info *type, int SWIGUNUSED first_arg, int *ret)
{
/*  there should be 2 params passed in
  (1) userdata (not the meta table)
  (2) string name of the attribute
*/
  int bases_search_result;
  int substack_start = duk_get_top(ctx)-2;
  assert(first_arg == substack_start+1);
  duk_checkstack(ctx,5);
  assert(duk_isuserdata(ctx,-2));  /* just in case */
  duk_getprototype(ctx,-2);    /* get the meta table */
  assert(duk_is_object(ctx,-1));  /* just in case */
  SWIG_duk_get_table(ctx,".get"); /* find the .get table */
  assert(duk_is_object(ctx,-1));  /* just in case */
  /* look for the key in the .get table */
  duk_pushvalue(ctx,substack_start+2);  /* key */
  duk_rawget(ctx,-2);
  duk_remove(ctx,-2); /* stack tidy, remove .get table */
  if (duk_iscfunction(ctx,-1))
  {  /* found it so call the fn & return its value */
    duk_pushvalue(ctx,substack_start+1);  /* the userdata */
    duk_call(ctx,1,1);  /* 1 value in (userdata),1 out (result) */
    duk_remove(ctx,-2); /* stack tidy, remove prototype */
    if(ret)
      *ret = 1;
    return SWIG_OK;
  }
  duk_pop_n(ctx,1);  /* remove whatever was there */
  /* ok, so try the .fn table */
  SWIG_duk_get_table(ctx,".fn"); /* find the .fn table */
  assert(duk_is_object(ctx,-1));  /* just in case */
  duk_pushvalue(ctx,substack_start+2);  /* key */
  duk_rawget(ctx,-2);  /* look for the fn */
  duk_remove(ctx,-2); /* stack tidy, remove .fn table */
  if (duk_isfunction(ctx,-1)) /* note: if its a C function or duk function */
  {  /* found it so return the fn & let duk call it */
    duk_remove(ctx,-2); /* stack tidy, remove prototype */
    if(ret)
      *ret = 1;
    return SWIG_OK;
  }
  duk_pop_n(ctx,1);  /* remove whatever was there */
  /* Remove the prototype */
  duk_pop_n(ctx,1);
  /* Search in base classes */
  bases_search_result = SWIG_duk_iterate_bases(ctx,type,substack_start+1,SWIG_duk_class_do_get,ret);
  return bases_search_result;  /* sorry not known */
}

/* the class getter method, performs the lookup of class attributes
 */
SWIGINTERN int SWIG_duk_class_getter(duk_context *ctx)
{
/*  there should be 2 params passed in
  (1) userdata (not the meta table)
  (2) string name of the attribute
*/
  int result;
  SWIG_duk_userdata *usr;
  SWIG_type_info *type;
  int ret = 0;
  assert(duk_is_pointer(ctx,-1));
  usr=(SWIG_duk_userdata*)duk_get_pointer(ctx,-11);  /* get data */
  type = usr->type;
  result = SWIG_duk_class_do_get(ctx,type,1,&ret);
  if(result == SWIG_OK)
    return ret;

  result = SWIG_duk_class_do_get_item(ctx,type,1,&ret);
  if(result == SWIG_OK)
    return ret;

  return 0;
}

/* This is the actual method exported to Lua. It calls SWIG_duk_class_do_set and correctly
 * handles return values.
 */
SWIGINTERN int SWIG_duk_class_set(duk_context *ctx)
{
/*  There should be 3 params passed in
  (1) table (not the meta table)
  (2) string name of the attribute
  (3) any for the new value
  */
  int ret = 0;
  int result;
  SWIG_duk_userdata *usr;
  SWIG_type_info *type;
  assert(duk_isuserdata(ctx,1));
  usr=(SWIG_duk_userdata*)duk_touserdata(ctx,1);  /* get data */
  type = usr->type;
  result = SWIG_duk_class_do_set(ctx,type,1,&ret);
  if(result != SWIG_OK) {
   SWIG_duk_pushferrstring(ctx,"Assignment not possible. No setter/member with this name. For custom assignments implement __setitem method.");
   duk_error(L);
  } else {
    assert(ret==0);
  }
  return 0;
}

/* the class.destruct method called by the interpreter */
SWIGINTERN int  SWIG_duk_class_destruct(duk_context *ctx)
{
/*  there should be 1 params passed in
  (1) userdata (not the meta table) */
  SWIG_duk_userdata *usr;
  SWIG_duk_class *clss;
  assert(duk_isuserdata(ctx,-1));  /* just in case */
  usr=(SWIG_duk_userdata*)duk_touserdata(ctx,-1);  /* get it */
  /* if must be destroyed & has a destructor */
  if (usr->own) /* if must be destroyed */
  {
    clss=(SWIG_duk_class*)usr->type->clientdata;  /* get the class */
    if (clss && clss->destructor)  /* there is a destroy fn */
    {
      clss->destructor(usr->ptr);  /* bye bye */
    }
  }
  return 0;
}

/* to manually disown some userdata */
SWIGINTERN int SWIG_duk_class_disown(duk_context *ctx)
{
/*  there should be 1 params passed in
  (1) userdata (not the meta table) */
  SWIG_duk_userdata *usr;
  assert(duk_is_pointer(ctx,-1));  /* just in case */
  usr=(SWIG_duk_userdata*)duk_get_pointer(ctx,-1);  /* get it */
  
  usr->own = 0; /* clear our ownership */
  return 0;
}

/* Duktape callable function to compare userdata's value
the issue is that two userdata may point to the same thing
but to Duktape, they are different objects */
SWIGRUNTIME duk_ret_t SWIG_duk_class_equal(duk_context *ctx)
{
  int result;
  SWIG_duk_userdata *usr1,*usr2;
  if (!duk_is_pointer(ctx,1) || !duk_is_pointer(ctx,2))  /* just in case */
    return 0;  /* return undefined */
  usr1=(SWIG_duk_userdata*)duk_get_pointer(ctx,1);  /* get data */
  usr2=(SWIG_duk_userdata*)duk_get_pointer(ctx,2);  /* get data */
  /*result=(usr1->ptr==usr2->ptr && usr1->type==usr2->type); only works if type is the same*/
  result=(usr1->ptr==usr2->ptr);
  duk_push_boolean(ctx,result);
  return 1;
}

/* creates the swig registry */
SWIGINTERN void SWIG_duk_create_class_registry(duk_context *ctx)
{
  /* create main SWIG registry object */
  duk_push_object(ctx);
  duk_push_string("SWIG", ctx);
  /* populate it with some predefined data */

  duk_push_object(ctx);
  duk_push_string("library", ctx);
  {
    /* list of metamethods that class inherits from its bases */
    duk_push_string(ctx,"prototypes");
    // FIXME duk_newtable(ctx);
    /* populate with list of metamethods */
    // FIXME SWIG_duk_populate_inheritable_metamethods(L);
    // FIXME duk_rawset(ctx,-3);
  }
  // FIXME duk_rawset(ctx,-3);

  // FIXME duk_rawset(ctx,LUA_REGISTRYINDEX);
}

/* gets the swig registry (or creates it) */
SWIGINTERN void SWIG_duk_get_class_registry(duk_context *ctx)
{
  /* add this all into the swig registry: */
  duk_push_string(ctx,"SWIG");
  // FIXME duk_rawget(ctx,LUA_REGISTRYINDEX);  /* get the registry */
  if (!duk_is_object(ctx,-1))  /* not there */
  {  /* must be first time, so add it */
    duk_pop_n(ctx,1);  /* remove the result */
    SWIG_duk_create_class_registry(ctx);
    /* then get it */
    duk_pushstring(ctx,"SWIG");
    duk_rawget(ctx,LUA_REGISTRYINDEX);
  }
}

SWIGINTERN void SWIG_duk_get_inheritable_metamethods(duk_context *ctx)
{
  SWIG_duk_get_class_registry(L);
  duk_pushstring(ctx, ".library");
  duk_rawget(ctx,-2);
  assert( !duk_isnil(ctx,-1) );
  duk_pushstring(ctx, "inheritable_metamethods");
  duk_rawget(ctx,-2);

  /* Remove class registry and library table */
  duk_remove(ctx,-2);
  duk_remove(ctx,-2);
}

/* Helper function to get the classes prototype from the register */
SWIGINTERN void  SWIG_duk_get_class_prototype(duk_context *ctx,const char *cname)
{
  SWIG_duk_get_class_registry(L);  /* get the registry */
  duk_pushstring(ctx,cname);  /* get the name */
  duk_rawget(ctx,-2);    /* get it */
  duk_remove(ctx,-2);    /* tidy up (remove registry) */
}

/* Set up the base classes pointers.
Each class structure has a list of pointers to the base class structures.
This function fills them.
It cannot be done at compile time, as this will not work with hireachies
spread over more than one swig file. 
Therefore it must be done at runtime, querying the SWIG type system.
*/
SWIGINTERN void SWIG_duk_init_base_class(duk_context *ctx,SWIG_duk_class *clss)
{
  int i=0;
  SWIG_module_info *module=SWIG_GetModule(ctx);
  for(i=0;clss->base_names[i];i++)
  {
    if (clss->bases[i]==0) /* not found yet */
    {
      /* lookup and cache the base class */
      SWIG_type_info *info = SWIG_TypeQueryModule(module,module,clss->base_names[i]);
      if (info) clss->bases[i] = (SWIG_duk_class *) info->clientdata;
    }
  }
}

/* helper add a variable to a registered class */
SWIGINTERN void SWIG_duk_add_variable(duk_context *ctx,const char *name,duk_CFunction getFn,duk_CFunction setFn)
{
  assert(duk_is_object(ctx,-1));  /* just in case */
  SWIG_duk_get_table(ctx,".get"); /* find the .get table */
  assert(duk_is_object(ctx,-1));  /* just in case */
  SWIG_duk_add_function(ctx,name,getFn);
  duk_pop_n(ctx,1);       /* tidy stack (remove table) */
  if (setFn)
  {
    SWIG_duk_get_table(ctx,".set"); /* find the .set table */
    assert(duk_is_object(ctx,-1));  /* just in case */
    SWIG_duk_add_function(ctx,name,setFn);
    duk_pop_n(ctx,1);       /* tidy stack (remove table) */
  }
}

/* helper to recursively add class static details (static attributes, operations and constants) */
SWIGINTERN void SWIG_duk_add_class_static_details(duk_context *ctx, SWIG_duk_class *clss)
{
  int i = 0;
  /* The class namespace table must be on the top of the stack */
  assert(duk_is_object(ctx,-1));
  /* call all the base classes first: we can then override these later: */
  for(i=0;clss->bases[i];i++)
  {
    SWIG_duk_add_class_static_details(ctx,clss->bases[i]);
  }

  SWIG_duk_add_namespace_details(ctx, clss->cls_static);
}

SWIGINTERN void SWIG_duk_add_class_user_metamethods(duk_context *ctx, SWIG_duk_class *clss); /* forward declaration */

/* helper to recursively add class details (attributes & operations) */
SWIGINTERN void  SWIG_duk_add_class_instance_details(duk_context *ctx, SWIG_duk_class *clss)
{
  int i;
  size_t bases_count = 0;
  /* Add bases to .bases table */
  SWIG_duk_get_table(ctx,".bases");
  assert(duk_is_object(ctx,-1));  /* just in case */
  for(i=0;clss->bases[i];i++)
  {
    SWIG_duk_get_class_prototype(ctx,clss->bases[i]->fqname);
    /* Base class must be already registered */
    assert(duk_is_object(ctx,-1));
    duk_rawseti(ctx,-2,i+1); /* In duk indexing starts from 1 */
    bases_count++;
  }
  assert(duk_rawlen(ctx,-1) == bases_count);
  duk_pop_n(ctx,1); /* remove .bases table */
  /* add attributes */
  for(i=0;clss->attributes[i].name;i++){
    SWIG_duk_add_variable(ctx,clss->attributes[i].name,clss->attributes[i].getmethod,clss->attributes[i].setmethod);
  }
  /* add methods to the prototype */
  SWIG_duk_get_table(ctx,".fn"); /* find the .fn table */
  assert(duk_is_object(ctx,-1));  /* just in case */
  for(i=0;clss->methods[i].name;i++){
    SWIG_duk_add_function(ctx,clss->methods[i].name,clss->methods[i].func);
  }
  duk_pop_n(ctx,1);       /* tidy stack (remove table) */
  /* add operator overloads
    This adds methods from prototype array to prototype. Can mess up garbage
    collectind if someone defines __gc method
    */
  if(clss->prototype) {
    for(i=0;clss->prototype[i].name;i++) {
      SWIG_duk_add_function(ctx,clss->prototype[i].name,clss->prototype[i].func);
    }
  }

  /* Adding metamethods that are defined in base classes. If bases were squashed
   * then it is obviously unnecessary
   */
  SWIG_duk_add_class_user_metamethods(ctx, clss);
}

/* Helpers to add user defined class metamedhods - __add, __sub etc. The helpers are needed
   for the following issue: Lua runtime checks for metamethod existence with rawget function
   ignoring our SWIG-provided __index and __newindex functions. Thus our inheritance-aware method
   search algorithm doesn't work in such case. (Not to say that Lua runtime queries metamethod directly
   in prototype and not in object).
   Current solution is this: if somewhere in hierarchy metamethod __x is defined, then all descendants
   are automatically given a special proxy __x that calls the real __x method.
   Obvious idea - to copy __x instead of creating __x-proxy is wrong because if someone changes __x in runtime,
   those changes must be reflected in all descendants.
*/

SWIGRUNTIME int SWIG_duk_resolve_metamethod(duk_context *ctx); /*forward declaration*/

/* The real function that resolves a metamethod.
 * Function searches given class and all it's bases(recursively) for first instance of something that is
 * not equal to SWIG_duk_resolve_metatmethod. (Almost always this 'something' is actual metamethod implementation
 * and it is a SWIG-generated C function.). It returns value on the top of the L and there is no garbage below the
 * answer.
 * Returns 1 if found, 0 otherwise.
 * clss is class which prototype we will search for method
 * metamethod_name_idx is index in L where metamethod name (as string) lies
 * skip_check allows to skip searching metamethod in givel clss and immideatelly go to searching in bases. skip_check
 * is not caried to subsequent recursive calls - false is always passed. It is set to true only at first call from
 * SWIG_duk_resolve_metamethod
 * */
SWIGINTERN int SWIG_duk_do_resolve_metamethod(duk_context *ctx, const SWIG_duk_class *clss, int metamethod_name_idx,
    int skip_check)
{
  /* This function is called recursively */
  int result = 0;
  int i = 0;

  if (!skip_check) {
    SWIG_duk_get_class_prototype(ctx, clss->fqname);
    duk_pushvalue(ctx, metamethod_name_idx);
    duk_rawget(ctx,-2);
    /* If this is cfunction and it is equal to SWIG_duk_resolve_metamethod then
     * this isn't the function we are looking for :)
     * duk_tocfunction will return NULL if not cfunction
     */
    if (!duk_isnil(ctx,-1) && duk_tocfunction(ctx,-1) != SWIG_duk_resolve_metamethod ) {
      duk_remove(ctx,-2); /* removing class prototype */
      return 1;
    }
    duk_pop_n(ctx,2); /* remove class prototype and query result */
  }

  /* Forwarding calls to bases */
  for(i=0;clss->bases[i];i++)
  {
    result = SWIG_duk_do_resolve_metamethod(ctx, clss->bases[i], metamethod_name_idx, 0);
    if (result)
      break;
  }

  return result;
}

/*
 * The proxy function for metamethod. All parameters are passed as closures.
 * Searches for actual method and calls it. 
 */
SWIGRUNTIME int SWIG_duk_resolve_metamethod(duk_context *ctx)
{
  int numargs;
  int metamethod_name_idx;
  const SWIG_duk_class* clss;
  int result;

  duk_checkstack(ctx,5);
  numargs = duk_get_top(ctx); /* number of arguments to pass to actual metamethod */
  
  /* Get upvalues from closure */
  duk_pushvalue(ctx, duk_upvalueindex(1)); /*Get function name*/
  metamethod_name_idx = duk_get_top(ctx);
  
  duk_pushvalue(ctx, duk_upvalueindex(2));
  clss = (const SWIG_duk_class*)(duk_touserdata(ctx,-1));
  duk_pop_n(ctx,1); /* remove lightuserdata with clss from stack */

  /* Actual work */
  result = SWIG_duk_do_resolve_metamethod(ctx, clss, metamethod_name_idx, 1);
  if (!result) {
   SWIG_duk_pushferrstring(ctx,"The metamethod proxy is set, but it failed to find actual metamethod. Memory corruption is most likely explanation.");
   duk_error(ctx);
   return 0;
  }

  duk_remove(ctx,-2); /* remove metamethod key */
  duk_insert(ctx,1); /* move function to correct position */
  duk_call(ctx, numargs, LUA_MULTRET);
  return duk_get_top(ctx); /* return all results */
}


/* If given metamethod must be present in given class, then creates appropriate proxy
 * Returns 1 if successfully added, 0 if not added because no base class has it, -1
 * if method is defined in the class prototype itself
 */
SWIGINTERN int SWIG_duk_add_class_user_metamethod(duk_context *ctx, SWIG_duk_class *clss, const int prototype_index)
{
  int key_index;
  int success = 0;
  int i = 0;

  /* metamethod name - on the top of the stack */
  assert(duk_is_string(ctx,-1));
  
  key_index = duk_get_top(ctx);

  /* Check whether method is already defined in prototype */
  duk_pushvalue(ctx,key_index); /* copy of the key */
  duk_get_heapptr(ctx,prototype_index);
  if( !duk_is_undefined(ctx,-1) ) {
    duk_pop_n(ctx,1);
    return -1;
  }
  duk_pop_n(ctx,1); 

  /* Iterating over immediate bases */
  for(i=0;clss->bases[i];i++)
  {
    const SWIG_duk_class *base = clss->bases[i];
    SWIG_duk_get_class_prototype(ctx, base->fqname);
    duk_pushvalue(ctx, key_index);
    duk_rawget(ctx, -2);
    if( !duk_isnil(ctx,-1) ) {
      duk_pushvalue(ctx, key_index); 

      /* Add proxy function */
      duk_pushvalue(ctx, key_index); /* first closure value is function name */
      duk_pushlightuserdata(ctx, clss); /* second closure value is SWIG_duk_class structure */
      duk_pushcclosure(ctx, SWIG_duk_resolve_metamethod, 2);
      
      duk_rawset(ctx, prototype_index);
      success = 1;
    }
    duk_pop_n(ctx,1); /* remove function or nil */
    duk_pop_n(ctx,1); /* remove base class prototype */

    if( success )
      break;
  }

  return success; 
}

SWIGINTERN void SWIG_duk_add_class_user_metamethods(duk_context *ctx, SWIG_duk_class *clss)
{
  int prototype_index;
  int metamethods_info_index;
  int tostring_undefined;
  int eq_undefined = 0;

  SWIG_duk_get_class_prototype(ctx, clss->fqname);
  prototype_index = duk_get_top(ctx);
  SWIG_duk_get_inheritable_metamethods(L);
  assert(duk_is_object(ctx,-1));
  metamethods_info_index = duk_get_top(ctx);
  duk_pushnil(L); /* first key */
  while(duk_next(ctx, metamethods_info_index) != 0 ) {
    /* key at index -2, value at index -1 */
    const int is_inheritable = duk_toboolean(ctx,-2);
    duk_pop_n(ctx,1); /* remove value - we don't need it anymore */

    if(is_inheritable) { /* if metamethod is inheritable */
      SWIG_duk_add_class_user_metamethod(ctx,clss,prototype_index);
    }
  }

  duk_pop_n(ctx,1); /* remove inheritable metatmethods table */

  /* Special handling for __tostring method */
  duk_pushstring(ctx, "__tostring");
  duk_pushvalue(ctx,-1);
  duk_rawget(ctx,prototype_index);
  tostring_undefined = duk_isnil(ctx,-1);
  duk_pop_n(ctx,1);
  if( tostring_undefined ) {
    duk_pushcfunction(ctx, SWIG_duk_class_tostring);
    duk_rawset(ctx, prototype_index);
  } else {
    duk_pop_n(ctx,1); /* remove copy of the key */
  }

  /* Special handling for __eq method */
  duk_pushstring(ctx, "__eq");
  duk_pushvalue(ctx,-1);
  duk_rawget(ctx,prototype_index);
  eq_undefined = duk_isnil(ctx,-1);
  duk_pop_n(ctx,1);
  if( eq_undefined ) {
    duk_pushcfunction(ctx, SWIG_duk_class_equal);
    duk_rawset(ctx, prototype_index);
  } else {
    duk_pop_n(ctx,1); /* remove copy of the key */
  }
  /* Warning: __index and __newindex are SWIG-defined. For user-defined operator[]
   * a __getitem/__setitem method should be defined
   */
  duk_pop_n(ctx,1); /* pop class prototype */
}

/* Register class static methods,attributes etc as well as constructor proxy */
SWIGINTERN void SWIG_duk_class_register_static(duk_context *ctx, SWIG_duk_class *clss)
{
  const int SWIGUNUSED begin = duk_get_top(ctx);
  duk_checkstack(ctx,5); /* just in case */
  assert(duk_is_object(ctx,-1));  /* just in case */
  assert(strcmp(clss->name, clss->cls_static->name) == 0); /* in class those 2 must be equal */

  SWIG_duk_namespace_register(ctx,clss->cls_static, 1);

  assert(duk_is_object(ctx,-1)); /* just in case */

  /*  add its constructor to module with the name of the class
  so you can do MyClass(...) as well as new_MyClass(...)
  BUT only if a constructor is defined
  (this overcomes the problem of pure virtual classes without constructors)*/
  if (clss->constructor)
  {
    duk_getprototype(ctx,-1);
    assert(duk_is_object(ctx,-1)); /* just in case */
    SWIG_duk_add_function(ctx,"__call", clss->constructor);
    duk_pop_n(ctx,1);
  }

  assert(duk_is_object(ctx,-1)); /* just in case */
  SWIG_duk_add_class_static_details(ctx, clss);

  /* clear stack */
  duk_pop_n(ctx,1);
  assert( duk_get_top(ctx) == begin );
}

/* Performs the instance (non-static) class registration process. Prototype for class is created
 * and added to the class registry.
 */
SWIGINTERN void  SWIG_duk_class_register_instance(duk_context *ctx,SWIG_duk_class *clss)
{
  const int SWIGUNUSED begin = duk_get_top(ctx);
  int i;
  /* if name already there (class is already registered) then do nothing */
  SWIG_duk_get_class_registry(L);  /* get the registry */
  duk_pushstring(ctx,clss->fqname);  /* get the name */
  duk_rawget(ctx,-2);
  if(!duk_isnil(ctx,-1)) {
    duk_pop_n(ctx,2);
    assert(duk_get_top(ctx)==begin);
    return;
  }
  duk_pop_n(ctx,2); /* tidy stack */
  /* Recursively initialize all bases */
  for(i=0;clss->bases[i];i++)
  {
    SWIG_duk_class_register_instance(ctx,clss->bases[i]);
  }
  /* Again, get registry and push name */
  SWIG_duk_get_class_registry(ctx);  /* get the registry */
  duk_pushstring(ctx,clss->fqname);  /* get the name */
  duk_push_object(ctx);    /* create the prototype */
  /* add string of class name called ".type" */
  duk_pushstring(ctx,".type");
  duk_pushstring(ctx,clss->fqname);
  duk_rawset(ctx,-3);
  /* add a table called bases */
  duk_push_string(ctx,".bases");
  duk_newtable(L);
  duk_rawset(ctx,-3);
  /* add a table called ".get" */
  duk_pushstring(ctx,".get");
  duk_newtable(L);
  duk_rawset(ctx,-3);
  /* add a table called ".set" */
  duk_pushstring(ctx,".set");
  duk_newtable(L);
  duk_rawset(ctx,-3);
  /* add a table called ".fn" */
  duk_pushstring(ctx,".fn");
  duk_newtable(L);
  /* add manual disown method */
  SWIG_duk_add_function(ctx,"__disown",SWIG_duk_class_disown);
  duk_rawset(ctx,-3);
  /* add accessor fns for using the .get,.set&.fn */
  SWIG_duk_add_function(ctx,"__index",SWIG_duk_class_get);
  SWIG_duk_add_function(ctx,"__newindex",SWIG_duk_class_set);
  SWIG_duk_add_function(ctx,"__gc",SWIG_duk_class_destruct);
  /* add it */
  duk_rawset(ctx,-3);  /* prototype into registry */
  duk_pop_n(ctx,1);      /* tidy stack (remove registry) */
  assert(duk_get_top(ctx) == begin);

  SWIG_duk_get_class_prototype(ctx,clss->fqname);
  SWIG_duk_add_class_instance_details(ctx,clss);  /* recursive adding of details (atts & ops) */
  duk_pop_n(ctx,1);      /* tidy stack (remove class prototype) */
  assert( duk_get_top(ctx) == begin );
}

SWIGINTERN void SWIG_duk_class_register(duk_context *ctx,SWIG_duk_class *clss)
{
  int SWIGUNUSED begin;
  assert(duk_is_object(ctx,-1)); /* This is a table (module or namespace) where classes will be added */
  SWIG_duk_class_register_instance(ctx,clss);
  SWIG_duk_class_register_static(ctx,clss);

  /* Add links from static part to instance part and vice versa */
  /* [SWIG registry]                                   [Module]
   *    "MyClass" ----> [MyClass prototype] <=====     "MyClass" -+> [static part]
   *                     ".get" ----> ...        |                |     getprototype()----|
   *                     ".set" ----> ...        |                |                       |
   *                     ".static" --------------)----------------/           [static part prototype]
   *                                             |                                ".get" --> ...
   *                                             |                                ".set" --> ....
   *                                             |=============================== ".instance"
   */
  begin = duk_get_top(ctx);
  duk_pushstring(ctx,clss->cls_static->name);
  duk_rawget(ctx,-2); /* get class static table */
  assert(duk_is_object(ctx,-1));
  duk_getprototype(ctx,-1);
  assert(duk_is_object(ctx,-1)); /* get class static prototype */
  duk_pushstring(ctx,".instance"); /* prepare key */

  SWIG_duk_get_class_prototype(ctx,clss->fqname); /* get class prototype */
  assert(duk_is_object(ctx,-1));
  duk_pushstring(ctx,".static"); /* prepare key */
  duk_pushvalue(ctx, -4); /* push static class TABLE */
  assert(duk_is_object(ctx,-1));
  duk_rawset(ctx,-3); /* assign static class table(!NOT prototype) as ".static" member of class prototype */
  duk_rawset(ctx,-3); /* assign class prototype as ".instance" member of class static METATABLE */
  duk_pop_n(ctx,2);
  assert(duk_get_top(ctx) == begin);
}

/* -----------------------------------------------------------------------------
 * Class/structure conversion fns
 * ----------------------------------------------------------------------------- */

/* helper to add prototype to new duk object */
SWIGINTERN void SWIG_duk_AddPrototype(duk_context *ctx,SWIG_type_info *type)
{
  if (type->clientdata)  /* there is clientdata: so add the prototype */
  {
    SWIG_duk_get_class_prototype(ctx,((SWIG_duk_class*)(type->clientdata))->fqname);
    if (duk_is_object(ctx,-1))
    {
      duk_setprototype(ctx,-2);
    }
    else
    {
      duk_pop_n(ctx,1);
    }
  }
}

/* pushes a new object into the duk stack */
SWIGRUNTIME void SWIG_duk_NewPointerObj(duk_context *ctx,void *ptr,SWIG_type_info *type, int own)
{
  SWIG_duk_userdata *usr;
  if (!ptr){
    duk_push_undefined(ctx);
    return;
  }
  usr=(SWIG_duk_userdata*)duk_newuserdata(ctx,sizeof(SWIG_duk_userdata));  /* get data */
  usr->ptr=ptr;  /* set the ptr */
  usr->type=type;
  usr->own=own;
  SWIG_duk_AddPrototype(ctx,type); /* add prototype */
}

/* takes a object from the duk stack & converts it into an object of the correct type
 (if possible) */
SWIGRUNTIME int  SWIG_duk_ConvertPtr(duk_context *ctx,int idx,void **ptr,SWIG_type_info *type,int flags)
{
  SWIG_duk_userdata *usr;
  SWIG_cast_info *cast;
  if (duk_is_undefined(ctx,idx)){*ptr=0; return SWIG_OK;}    /* special case: duk nil => NULL pointer */
  usr=(SWIG_duk_userdata*)duk_get_pointer(ctx,idx);  /* get data */
  if (usr)
  {
    if (flags & SWIG_POINTER_DISOWN) /* must disown the object */
    {
        usr->own=0;
    }
    if (!type)            /* special cast void*, no casting fn */
    {
      *ptr=usr->ptr;
      return SWIG_OK; /* ok */
    }
    cast=SWIG_TypeCheckStruct(usr->type,type); /* performs normal type checking */
    if (cast)
    {
      int newmemory = 0;
      *ptr=SWIG_TypeCast(cast,usr->ptr,&newmemory);
      assert(!newmemory); /* newmemory handling not yet implemented */
      return SWIG_OK;  /* ok */
    }
  }
  return SWIG_ERROR;  /* error */
}

SWIGRUNTIME void* SWIG_duk_MustGetPtr(duk_context *ctx,int index,SWIG_type_info *type,int flags,
       int argnum,const char *func_name){
  void *result;
  if (!SWIG_IsOK(SWIG_ConvertPtr(ctx,index,&result,type,flags))){
    dukL_error (ctx,"Error in %s, expected a %s at argument number %d\n",
		func_name,(type && type->str)?type->str:"void*",argnum);
  }
  return result;
}

/* pushes a packed userdata. use for member fn pointers only */
SWIGRUNTIME void SWIG_duk_NewPackedObj(duk_context *ctx,void *ptr,size_t size,SWIG_type_info *type)
{
  SWIG_duk_rawdata *raw;
  assert(ptr); /* not acceptable to pass in a NULL value */
  raw=(SWIG_duk_rawdata*)duk_newuserdata(ctx,sizeof(SWIG_duk_rawdata)-1+size);  /* alloc data */
  raw->type=type;
  raw->own=0;
  memcpy(raw->data,ptr,size); /* copy the data */
  SWIG_duk_AddPrototype(ctx,type); /* add prototype */
}
    
/* converts a packed userdata. use for member fn pointers only */
SWIGRUNTIME int  SWIG_duk_ConvertPacked(duk_context *ctx,int idx,void *ptr,size_t size,SWIG_type_info *type)
{
  SWIG_duk_rawdata *raw;
  raw=(SWIG_duk_rawdata*)duk_get_pointer(ctx,idx);  /* get data */
  if (!raw) return SWIG_ERROR;  /* error */
  if (type==0 || type==raw->type) /* void* or identical type */
  {
    memcpy(ptr,raw->data,size); /* copy it */
    return SWIG_OK; /* ok */
  }
  return SWIG_ERROR;  /* error */
}

/* a function to get the typestring of a piece of data */
SWIGRUNTIME const char *SWIG_duk_typename(duk_context *ctx, duk_idx_t tp)
{
  SWIG_duk_userdata *usr;
  if (duk_is_pointer(ctx,tp))
  {
    usr=(SWIG_duk_userdata*)duk_to_pointer(ctx,tp);  /* get data */
    if (usr && usr->type && usr->type->str)
      return usr->type->str;
    return "userdata (unknown type)";
  }
  return duk_typename(ctx,duk_type(ctx,tp));
}

/* Duk callable function to get the userdata's type */
SWIGRUNTIME int SWIG_duk_type(duk_context *ctx)
{
  duk_push_string(ctx,SWIG_duk_typename(ctx,1));
  return 1;
}

/* -----------------------------------------------------------------------------
 * global variable support code: class/struct typemap functions
 * ----------------------------------------------------------------------------- */

/* 
 * Install properties into an object.
 * This asserts that the target object is on the top of the value stack on entry.
 */
SWIGINTERN void
SWIG_duk_install_const_properties(duk_context *ctx, SWIG_duk_js_property[] properties) {
  duk_idx_t obj_idx = -1;
  assert(duk_is_object(ctx, obj_idx)); /* This better be the right object! */

  for(i = 0; i < sizeof(properties) / sizeof(SWIG_duk_js_property); i++)
  {
    /* FIXME: This seems inefficient. */
    if (properties[i].propertyName == NULL) {
      break;
    }

    duk_push_string(ctx, properties[i].propertyName);
    duk_push_c_function(ctx, properties[i].getter, 0 /* nargs */);
    duk_push_c_function(ctx, properties[i].setter, 1 /* nargs */);
    duk_def_prop(ctx, obj_idx,
                 DUK_DEFPROP_HAVE_GETTER |
                 DUK_DEFPROP_HAVE_SETTER);
  }
}

/* -----------------------------------------------------------------------------
 * executing Javascript code from within the wrapper
 * ----------------------------------------------------------------------------- */

#ifndef SWIG_DOSTRING_FAIL /* Allows redefining of error function */
#define SWIG_DOSTRING_FAIL(S) fprintf(stderr,"%s\n",S)
#endif
/*
 * Executes a C string in Duktape
 */
SWIGINTERN int 
SWIG_duk_dostring(duk_context *ctx, const char *str) {
  duk_idx_t top, ret;
  if (str==0 || str[0]==0) return 0; /* nothing to do */
  top=duk_get_top(ctx); /* save stack */
  ret = duk_peval_string(ctx, str);
  if (duk_is_eval_error(ctx, ret)) {
    /* Handle eval error */
  }
  duk_set_top(ctx, top); /* restore the stack */
  return 0;
}    

#ifdef __cplusplus
}
#endif

/* ------------------------------ end javascriptrun.swg  ------------------------------ */
