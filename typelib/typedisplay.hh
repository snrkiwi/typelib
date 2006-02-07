#ifndef TYPELIB_DISPLAYVISITOR_HH
#define TYPELIB_DISPLAYVISITOR_HH

#include "typevisitor.hh"
#include <iosfwd>

namespace Typelib
{
    class TypeDisplayVisitor : public TypeVisitor
    {
        template<typename T>
        void display_compound(T const& type, char const* compound_name);

        std::ostream& m_stream;
        std::string   m_indent;

    protected:
        bool visit_(Compound const& type);
        bool visit_(Compound const& type, Field const& field);
        
        bool visit_(Numeric const& type);
        bool visit_(Enum const& type);
       
        bool visit_(Pointer const& type);
        bool visit_(Array const& type);

    public:
        TypeDisplayVisitor(std::ostream& stream, std::string const& base_indent);
    };

    namespace details
    {
        struct do_type_display
        {
            Type const& type;
            std::string indent;
            do_type_display(Type const& type_, std::string const& indent_ = "")
                : type(type_), indent(indent_) {}
        };
        inline std::ostream& operator << (std::ostream& stream, do_type_display display)
        {
            TypeDisplayVisitor visitor(stream, display.indent);
            visitor.apply(display.type);
            return stream;
        }
    }
    inline details::do_type_display type_display(Type const& type, std::string const& indent = "")
    { return details::do_type_display(type, indent); }
    inline std::ostream& operator << (std::ostream& stream, Type const& type)
    { return stream << type_display(type); }
}

#endif

