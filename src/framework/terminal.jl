"""
    struct Terminal end
    
Type of the unique value representing the output of a decision node as being terminal or
otherwise exceptional. 
"""
struct Terminal end

"""
    terminal

Unique value representing the output of a decision node as being terminal or
otherwise exceptional. The singleton instance of type `Terminal`.
"""
const terminal = Terminal()

"""
    isterminal(x)

Return `true` if and only if `x === terminal`, and `false` otherwise, in the style of
`isnothing`.
"""
isterminal(::Terminal) = true
isterminal(::Any) = false