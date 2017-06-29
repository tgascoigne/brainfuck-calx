package bfuck;

// The stack
type Stack struct {
	top: *StackNode,
};

// A value on the stack
type StackNode struct {
	prev: *StackNode,
	val: any
};

// Push a new value onto the stack
stack_push := fn(s: *Stack, val: any) {
	node := &StackNode{
		prev: s.top,
		val: val,
	};
	s.top = node;
};

// Pop a value from the stack
stack_pop := fn(s: *Stack) -> any {
	node := s.top;
	s.top = node.prev;
	return node.val;
};

// Peek the top value on the stack
stack_peek := fn(s: *Stack) -> any {
	return s.top.val;
};
