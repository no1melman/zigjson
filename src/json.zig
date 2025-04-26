const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const ArrayList = std.ArrayList(u8);

const JsonTokenType = enum { none, start_object, end_object, start_array, end_array, property, comment, string, number, boolean, null, undefined };

const start_object = '{';
const end_object = '}';
const start_array = '[';
const end_array = ']';
const comment = '/';
const quote = '"';
const colon = ':';
const true_char = 't';
const false_char = 'f';

const true_value = "true";
const false_value = "false";

const ReadResultTag = enum { ok, need_more };
const ReadResult = union(ReadResultTag) { ok: void, need_more: void };

const ReaderPosition = struct { index: usize = 0 };

const JsonError = error{ ExpectedBoolean, ExpectedProperty, ExpectedValue, ExpectedEndOfArray, ExpectedEndOfObject, UnexpectedSyntax };

fn objectParser(reader: *Utf8JsonReader) JsonError!ReadResult {
    reader.token_type = .start_object;
    return .ok;
}

fn arrayParser(reader: *Utf8JsonReader) JsonError!ReadResult {
    reader.token_type = .start_array;
    return .ok;
}

fn propertyParser(reader: *Utf8JsonReader) JsonError!ReadResult {
    reader.token_type = .property;
    const result = try reader.readString();
    return if (result) .ok else .need_more;
}

const ParserType = fn (*Utf8JsonReader) JsonError!ReadResult;
// struct that holds the error
const FailParserContext = struct {
    err: JsonError,

    pub fn parser(self: *FailParserContext, reader: *Utf8JsonReader) JsonError!ReadResult {
        _ = reader; // ignore reader
        return self.err;
    }
};
fn failParser(errorToReturn: JsonError) ParserType {
    const ctx = FailParserContext{ .err = errorToReturn };

    return ctx.parser;
}

fn valueParser(reader: *Utf8JsonReader) JsonError!ReadResult {
    const current_char = reader.advancePosition() orelse return .need_more;

    const next_parser: fn (reader: *Utf8JsonReader) JsonError!ReadResult = switch (current_char) {
        start_object => objectParser,
        start_array => arrayParser,
        else => failParser(.ExpectedValue),
    };

    return next_parser(reader);
}

const Utf8JsonReader = struct {
    position: ReaderPosition,
    buffer: *const []u8,
    token_type: JsonTokenType = .none,
    previouse_token_type: JsonTokenType = .none,
    expected_next: []JsonTokenType,
    internal_buffer: ArrayList,
    pre_colon: bool = true,

    fn advancePosition(self: *Utf8JsonReader) ?u8 {
        if (self.position.index < self.buffer.len) {
            const next_char = self.buffer.*[self.position.index];
            self.position.index += 1;
            return next_char;
        }
        return null;
    }
    pub fn readNext(self: *Utf8JsonReader) !bool {
        const current_char = advancePosition(self) orelse return false;

        print("read next: {c}\n", .{current_char});

        // need to discern the actual token read...
        // rather than do this switch, i think we should have a parser field,
        // when we hit one of these "tokens" then we set the parser to what we want next
        //   i.e.
        //     object => next parser = property parser
        //     array => next parser = value parser (aka self)
        //     string => if (last parser was property) then string parser
        self.token_type = tc: switch (current_char) {
            start_object => .start_object, // after reading this token type, we should set the next parser
            end_object => .end_object,
            start_array => .start_array,
            end_array => .end_array,
            colon => {
                self.pre_colon = false;
                const next_char = advancePosition(self) orelse return false;
                // keep the switch going...
                continue :tc next_char;
            },
            quote => if (self.pre_colon) .property else .string,
            true_char => .boolean,
            false_char => .boolean,
            else => .none
        };
        // i think the best bet is to have a backing field in the struct to hold the buffer
        // that way if it's a string, you can return it..., or cast it depending on its type

        if (self.token_type == .property or self.token_type == .string) {
            // collect all the string into the internal buffer...
            return self.readString();
        }
        if (self.token_type == .boolean) {
            return self.readBool();
        }

        return true;
    }

    fn readString(self: *Utf8JsonReader) !bool {
        self.internal_buffer.clearAndFree();
        var string_char = advancePosition(self) orelse return false;
        while (string_char != quote) {
            print("  collecting string char: {c}\n", .{string_char});
            try self.internal_buffer.append(string_char);
            string_char = advancePosition(self) orelse return false;
        }
        print(" grabbed string: {s}\n", .{self.internal_buffer.items});
        self.pre_colon = !self.pre_colon;
        return true;
    }

    fn readBool(self: *Utf8JsonReader) !bool {
        // clear internal_buffer
        self.internal_buffer.clearAndFree();

        // because the read_token would have processed the first char, get it
        const current_char = self.buffer.*[self.position.index];
        const len: usize = if (current_char == true_char) 4 else 5;

        // create the boolean literal buffer
        try self.internal_buffer.append(current_char);

        var counter: usize = 1;
        var next_char: u8 = undefined;
        while (counter < len) {
            next_char = self.advancePosition() orelse return false;
            try self.internal_buffer.append(next_char);
            counter += 1;
        }

        const result = self.internal_buffer.items;
        return if (std.mem.eql(u8, result, true_value)) true else if (std.mem.eql(u8, result, false_value)) true else error.ExpectedBoolean;
    }

    pub fn getString(self: *Utf8JsonReader) []u8 {
        return self.internal_buffer.items;
    }
    pub fn getBool(self: *Utf8JsonReader) bool {
        const result = self.internal_buffer.items;
        return if (std.mem.eql(u8, result, true_value)) true else if (std.mem.eql(u8, result, false_value)) false else false;
    }
};

pub fn CreateReader(buffer: *const []u8, allocator: mem.Allocator) !Utf8JsonReader {
    const position = ReaderPosition{ .index = 0 };
    const reader = Utf8JsonReader{ .position = position, .buffer = buffer, .expected_next = undefined, .internal_buffer = ArrayList.init(allocator) };

    return reader;
}
