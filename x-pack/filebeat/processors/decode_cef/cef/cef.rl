// Code generated by ragel DO NOT EDIT.
package cef

import (
    "fmt"
    "strconv"

    "go.uber.org/multierr"
)

%%{
    machine cef;
    write data;
    variable p p;
    variable pe pe;
}%%

// unpack unpacks a CEF message.
func (e *Event) unpack(data string) error {
    cs, p, pe, eof := 0, 0, len(data), len(data)
    mark, mark_slash := 0, 0
    var escapes []int

    // Extension key.
    var extKey string

    // Extension value start and end indices.
    extValueStart, extValueEnd := 0, 0

    // recoveredErrs are problems with the message that the parser was able to
    // recover from (though the parsing might not be "correct").
    var recoveredErrs []error

    e.init(data)

    %%{
        # Actions to execute while executing state machine.
        action mark {
            mark = p
        }
        action mark_slash {
            mark_slash = p
        }
        action mark_escape {
            escapes = append(escapes, mark_slash, p)
        }
        action version {
            e.Version, _ = strconv.Atoi(data[mark:p])
        }
        action device_vendor {
            e.DeviceVendor = replaceEscapes(data[mark:p], mark, escapes)
            escapes = escapes[:0]
        }
        action device_product {
            e.DeviceProduct = replaceEscapes(data[mark:p], mark, escapes)
            escapes = escapes[:0]
        }
        action device_version {
            e.DeviceVersion = replaceEscapes(data[mark:p], mark, escapes)
            escapes = escapes[:0]
        }
        action device_event_class_id {
            e.DeviceEventClassID = replaceEscapes(data[mark:p], mark, escapes)
            escapes = escapes[:0]
        }
        action name {
            e.Name = replaceEscapes(data[mark:p], mark, escapes)
            escapes = escapes[:0]
        }
        action severity {
            e.Severity = data[mark:p]
        }
        action extension_key {
            // A new extension key marks the end of the last extension value.
            if len(extKey) > 0 && extValueStart <= mark - 1 {
                e.pushExtension(extKey, replaceEscapes(data[extValueStart:mark-1], extValueStart, escapes))
                extKey, extValueStart, extValueEnd, escapes = "", 0, 0, escapes[:0]
            }
            extKey = data[mark:p]
        }
        action extension_value_start {
            extValueStart = p;
            extValueEnd = p
        }
        action extension_value_mark {
            extValueEnd = p+1
        }
        action extension_eof {
            // Reaching the EOF marks the end of the final extension value.
            if len(extKey) > 0 && extValueStart <= extValueEnd {
                e.pushExtension(extKey, replaceEscapes(data[extValueStart:extValueEnd], extValueStart, escapes))
                extKey, extValueStart, extValueEnd, escapes = "", 0, 0, escapes[:0]
            }
        }
        action extension_err {
            recoveredErrs = append(recoveredErrs, fmt.Errorf("malformed value for %s at pos %d", extKey, p+1))
            fhold; fnext gobble_extension;
        }
        action recover_next_extension {
            extKey, extValueStart, extValueEnd = "", 0, 0
            // Resume processing at p, the start of the next extension key.
            p = mark;
            fnext extensions;
        }

        # Define what header characters are allowed.
        pipe = "|";
        escape = "\\";
        escape_pipe = escape pipe;
        backslash = "\\\\";
        header_escapes = (backslash | escape_pipe) >mark_slash %mark_escape;
        device_chars = header_escapes | (any -- pipe -- escape);
        severity_chars = ( alpha | digit | "-" );

        # Header fields.
        version = "CEF:" digit+ >mark %version;
        device_vendor = device_chars* >mark %device_vendor;
        device_product = device_chars* >mark %device_product;
        device_version = device_chars* >mark %device_version;
        device_event_class_id = device_chars* >mark %device_event_class_id;
        name = device_chars* >mark %name;
        severity = severity_chars* >mark %severity;

        header = version pipe
                 device_vendor pipe
                 device_product pipe
                 device_version pipe
                 device_event_class_id pipe
                 name pipe
                 severity pipe;

        # Define what extension characters are allowed.
        equal = "=";
        escape_equal = escape equal;
        escape_newline = escape 'n';
        escape_carriage_return = escape 'r';
        extension_value_escapes = (escape_equal | backslash | escape_newline | escape_carriage_return) >mark_slash %mark_escape;
        # Only alnum is defined in the CEF spec. The other characters allow
        # non-conforming extension keys to be parsed.
        extension_key_start_chars = alnum | '_';
        extension_key_chars = extension_key_start_chars | '.' | ',' | '[' | ']';
        extension_key_pattern = extension_key_start_chars extension_key_chars*;
        extension_value_chars_nospace = extension_value_escapes | (any -- equal -- escape -- space);

        # Extension fields.
        extension_key = extension_key_pattern >mark %extension_key;
        extension_value = (space* extension_value_chars_nospace @extension_value_mark)* >extension_value_start $err(extension_err);
        extension = extension_key equal extension_value;
        extensions = " "* extension (space* " " extension)* space* %/extension_eof;

        # gobble_extension attempts recovery from a malformed value by trying to
        # advance to the next extension key and re-entering the main state machine.
        gobble_extension := any* (" " >mark) extension_key_pattern equal @recover_next_extension;

        # CEF message.
        cef = header extensions?;

        main := cef;
        write init;
        write exec;
    }%%

    // Check if state machine completed.
    if cs < cef_first_final {
        // Reached an early end.
    	if p == pe {
    		return multierr.Append(multierr.Combine(recoveredErrs...), fmt.Errorf("unexpected end of CEF event"))
    	}

        // Encountered invalid input.
    	return multierr.Append(multierr.Combine(recoveredErrs...), fmt.Errorf("error in CEF event at pos %d", p+1))
    }

    return multierr.Combine(recoveredErrs...)
}
