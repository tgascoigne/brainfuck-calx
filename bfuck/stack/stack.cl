package stack

// The stack
type Stack <T>struct {
	top: *<T>Node,
}

// A value on the stack
type Node <T>struct {
	prev: *<T>Node,
	val: T,
}

// Push a new value onto the stack
push :: <T>fn(s: *<T>Stack, val: T) {
	node := &<T>Node{
		prev: s.top,
		val: val,
	}
	s.top = node
}

// Pop a value from the stack
pop :: <T>fn(s: *<T>Stack) -> T {
	node := s.top
	s.top = node.prev
	return node.val
}

// Peek the top value on the stack
peek :: <T>fn(s: *<T>Stack) -> T {
	return s.top.val
}
