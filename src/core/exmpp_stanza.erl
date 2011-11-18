%% Copyright ProcessOne 2006-2010. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.

%% @author Mickael Remond <mickael.remond@process-one.net>
%% @author Jean-Sébastien Pédron <js.pedron@meetic-corp.com>

%% @doc
%% The module <strong>{@module}</strong> provides helpers to manipulate
%% standard stanza.

-module(exmpp_stanza).

-include("exmpp.hrl").

%% avoid name clash with local error/2 function
-compile({no_auto_import,[error/2]}).

%% Stanza common components.
-export([
	 get_error/1
	]).

%% Stanza standard attributes.
-export([
	 get_sender/1,
	 set_sender/2,
	 remove_sender/1,
	 get_recipient/1,
	 set_recipient/2,
	 remove_recipient/1,
	 set_jids/3,
	 get_id/1,
	 set_id/2,
	 get_type/1,
	 set_type/2,
	 get_lang/1,
	 set_lang/2
	]).

%% Common operations.
-export([
	 reply/1,
	 reply_without_content/1,
	 reply_with_error/2
	]).

%% Stanza-level errors.
-export([
	 error/1,
	 error/2,
	 stanza_error/2,
	 stanza_error_without_original/2,
	 is_stanza_error/1,
	 get_error_type/1,
	 set_error_type/2,
	 set_error_type_from_condition/2,
	 get_condition/1,
	 get_text/1
	]).

%% Serialization wrappers.
-export([
	 to_list/2,
	 to_list/3,
	 to_list/1,
	 to_binary/2,
	 to_binary/3,
	 to_binary/1,
	 to_iolist/2,
	 to_iolist/3,
	 to_iolist/1
	]).

%% --------------------------------------------------------------------
%% Documentation / type definition.
%% --------------------------------------------------------------------

-type(jidlike() :: exmpp_jid:jid() | binary() | string()).
-type(id()      :: binary() | string() | random | undefined).
-type(type()    :: binary() | string() | integer() | atom()).
-type(lang()    :: binary() | string() | undefined).

%% --------------------------------------------------------------------
%% Stanza common components.
%% --------------------------------------------------------------------

%% @spec (Stanza) -> Error | undefined
%%     Stanza = exml:xmlel() | iq()
%%     Error = exml:xmlel()
%% @doc Return the error element from `Stanza'.
%%
%% The error element is supposed to have the name `error' and the same
%% namespace as the stanza.

-spec(get_error/1 :: (exml:xmlel()) -> exml:xmlel() | undefined).

get_error({xmlel, _, _, _} = Stanza) ->
    exml:get_element(Stanza, 'error');
get_error(#iq{type = error, error = Error}) ->
    Error;
get_error(#iq{}) ->
    undefined.

%% --------------------------------------------------------------------
%% Stanza standard attributes.
%% --------------------------------------------------------------------

%% @spec (Stanza) -> Sender | undefined
%%     Stanza = exmpp_xml:xmlel()
%%     Sender = binary()
%% @doc Return the sender.
%%
%% The return value should be a JID and may be parsed with
%% {@link exmpp_jid:parse/1}.

-spec(get_sender/1 :: (exml:xmlel()) -> binary() | undefined).

get_sender(Stanza) ->
    exml:get_attribute(Stanza, <<"from">>, undefined).


%% @spec (Stanza, Sender) -> New_Stanza
%%     Stanza = exmpp_xml:xmlel()
%%     Sender =  binary() 
%%     New_Stanza = exmpp_xml:xmlel()
%% @doc Set the sender.
%%
-spec(set_sender/2 ::
	(exml:xmlel(), binary() ) -> exml:xmlel()).

set_sender(Stanza, Sender) ->
    exml:set_attribute(Stanza, <<"from">>, Sender).


%% @spec (Stanza) -> New_Stanza
%%     Stanza = exmpp_xml:xmlel()
%%     New_Stanza = exmpp_xml:xmlel()
%% @doc Remove the sender.

-spec(remove_sender/1 :: (exml:xmlel()) -> exml:xmlel()).

remove_sender(Stanza) ->
    exml:remove_attribute(Stanza, <<"from">>).


%% @spec (Stanza) -> Recipient | undefined
%%     Stanza = exml:xmlel()
%%     Recipient = binary()
%% @doc Return the recipient.
%%
%% The return value should be a JID and may be parsed with
%% {@link exmpp_jid:parse/1}.

-spec(get_recipient/1 :: (exml:xmlel()) -> binary() | undefined).

get_recipient(Stanza) ->
    exml:get_attribute(Stanza, <<"to">>, undefined).


%% @spec (Stanza, Recipient) -> New_Stanza
%%     Stanza = exml:xmlel()
%%     Recipient =  binary() 
%%     New_Stanza = exml:xmlel()
%% @doc Set the recipient.
%%

-spec(set_recipient/2 ::
	(exml:xmlel(), binary() ) -> exml:xmlel()).

set_recipient(Stanza, Recipient) ->
    exml:set_attribute(Stanza, <<"to">>, Recipient).


%% @spec (Stanza) -> New_Stanza
%%     Stanza = exml:xmlel()
%%     New_Stanza = exml:xmlel()
%% @doc Remove the recipient.

-spec(remove_recipient/1 :: (exml:xmlel()) -> exml:xmlel()).

remove_recipient(Stanza) -> 
	exml:remove_attribute(Stanza, <<"to">>).


%% @spec (Stanza, Sender, Recipient) -> New_Stanza
%%     Stanza = exmpp_xml:xmlel()
%%     Sender = exmpp_jid:jid() | binary() | string() | undefined
%%     Recipient = exmpp_jid:jid() | binary() | string() | undefined
%%     New_Stanza = exmpp_xml:xmlel()
%% @doc Set the sender and the recipient at the same time.
%%
%% If `Sender' is set to `undefined', the sender is removed. If
%% `Recipient' is set to `undefined', the recipient is removed.

-spec(set_jids/3 ::
      (#xmlel{}, jidlike(), jidlike()) -> #xmlel{}).

set_jids(Stanza, From, To) ->
    set_recipient(set_sender(Stanza, From), To).



%% @spec (Stanza) -> ID | undefined
%%     Stanza = exml:xmlel() | exmpp_iq:iq()
%%     ID = binary()
%% @doc Return the stanza ID.

-spec(get_id/1 :: (exml:xmlel() | #iq{}) -> binary() | undefined).

get_id(#iq{id = ID}) ->
    ID;
get_id(Stanza) ->
    exml:get_attribute(Stanza, <<"id">>).


%% @spec (Stanza, ID) -> New_Stanza
%%     Stanza = exml:xmlel() | exmpp_iq:iq()
%%     ID = binary() | random 
%%     New_Stanza = exml:xmlel() | exmpp_iq:iq()
%% @doc Set the ID.
%%

-spec(set_id/2 :: (#xmlel{} | #iq{}, id()) -> #xmlel{} | #iq{}).

set_id({xmlel, Name, _, _} = Stanza, random) ->
    set_id(Stanza, exmpp_utils:random_id(Name));
set_id({xmlel, _, _, _} = Stanza, ID) ->
	exml:set_attribute(Stanza, <<"id">>, ID);
set_id(#iq{} = Stanza, random) ->
    ID = exmpp_utils:random_id("iq"),
    set_id(Stanza, ID);
set_id(#iq{} = Stanza, ID) ->
    Stanza#iq{id = ID}.

%% @spec (Stanza) -> Type | undefined
%%     Stanza = exml:xmlel() | exmpp_iq:iq()
%%     Type = binary()
%% @doc Return the type of the stanza.

-spec(get_type/1 :: (exml:xmlel() | #iq{}) -> binary() | undefined).

get_type({xmlel, _N, _Attr, _Child}=El) ->
    exml:get_attribute(El, <<"type">>, undefined);

get_type(#iq{type = Type}) ->
    type_to_binary(Type).

type_to_binary(Type) when is_atom(Type) ->
    case Type of
        'get'     -> <<"get">>;
        'set'     -> <<"set">>;
        'result'  -> <<"result">>;
        'error'   -> <<"error">>;
        undefined -> undefined;
        _         -> list_to_binary(atom_to_list(Type))
    end.


%% @spec (Stanza, Type) -> New_Stanza
%%     Stanza = exmpp_xml:xmlel() | exmpp_iq:iq()
%%     Type = atom() | binary() 
%%     New_Stanza = exmpp_xml:xmlel() | exmpp_iq:iq()
%% @doc Set the type of the stanza.

-spec(set_type/2 :: (#xmlel{} | #iq{}, type()) -> #xmlel{} | #iq{}).

set_type({xmlel, _, _, _} = Stanza, Type) ->
    exml:set_attribute(Stanza, <<"type">>, Type);
set_type(#iq{} = Stanza, <<"get">>) ->
    Stanza#iq{type = <<"get">>, kind = request};
set_type(#iq{} = Stanza, <<"set">>) ->
    Stanza#iq{type = <<"set">>, kind = request};
set_type(#iq{} = Stanza, <<"result">>) ->
    Stanza#iq{type = <<"result">>, kind = response};
set_type(#iq{} = Stanza, <<"error">>) ->
    Stanza#iq{type = <<"error">>, kind = response}.


%% @spec (Stanza) -> Lang | undefined
%%     Stanza = exmpp_xml:xmlel() | exmpp_iq:iq()
%%     Lang = binary()
%% @doc Return the language of the stanza.

-spec(get_lang/1 :: (#xmlel{} | #iq{}) -> binary() | undefined).

get_lang({xmlel, _, _, _} = Stanza) ->
    case exml:get_attribute(Stanza, <<"lang">>) of
	    undefined -> exml:get_attribute(Stanza, <<"xml:lang">>);
	    Lang -> Lang
    end;
get_lang(#iq{lang = Lang}) ->
    Lang.

%% @spec (Attrs) -> Lang | undefined
%%     Attrs = [exmpp_xml:xmlattr()]
%%     Lang = binary()
%% @doc Return the language of the stanza.

-spec(get_lang_from_attrs/1 :: ([#xmlattr{}]) -> binary() | undefined).

get_lang_from_attrs(Attrs) ->
    exmpp_xml:get_attribute_from_list_as_binary(Attrs, ?NS_XML, <<"lang">>,
						undefined).

%% @spec (Stanza, Lang) -> New_Stanza
%%     Stanza = exmpp_xml:xmlel() | exmpp_iq:iq()
%%     Lang = binary() | string() | undefined
%%     New_Stanza = exmpp_xml:xmlel() | exmpp_iq:iq()
%% @doc Set the lang.
%%
%% If `Lang' is `undefined' or empty, it's removed.

-spec(set_lang/2 :: (#xmlel{} | #iq{}, lang()) -> #xmlel{} | #iq{}).

set_lang(#xmlel{attrs = Attrs} = Stanza, Lang) ->
    New_Attrs = set_lang_in_attrs(Attrs, Lang),
    Stanza#xmlel{attrs = New_Attrs};
set_lang(#iq{} = Stanza, Lang) ->
    Stanza#iq{lang = Lang}.

%% @spec (Attrs, Lang) -> New_Attrs
%%     Attrs = [exmpp_xml:xmlattr()]
%%     Lang = binary() | string() | undefined
%%     Attrs = [exmpp_xml:xmlattr()]
%% @doc Set the lang.
%%
%% If `Lang' is `undefined' or empty, it's removed.

-spec(set_lang_in_attrs/2 :: ([#xmlattr{}], lang()) -> [#xmlattr{}]).

set_lang_in_attrs(Attrs, Lang)
  when Lang == undefined; Lang == <<>>; Lang == "" ->
    exmpp_xml:remove_attribute_from_list(Attrs, ?NS_XML, <<"lang">>);
set_lang_in_attrs(Attrs, Lang) ->
    exmpp_xml:set_attribute_in_list(Attrs, ?NS_XML, <<"lang">>, Lang).

%% --------------------------------------------------------------------
%% Common operations.
%% --------------------------------------------------------------------

%% @spec (Stanza) -> Stanza_Reply
%%     Stanza = exml:xmlel()
%%     Stanza_Reply = exml:xmlel()
%% @doc Prepare a reply to `Stanza'.
%%
%% @see reply_from_attrs/1.

-spec(reply/1 :: (exml:xmlel()) -> exml:xmlel()).
reply(Stanza) ->
    From = get_sender(Stanza),
    To = get_recipient(Stanza),
    S1 = case From of
	    undefined ->
		    exml:remove_attribute(Stanza, <<"to">>);
	     _ ->
		     set_recipient(Stanza, From)
    end,
    case To of
	    undefined ->
		    exml:remove_attribute(S1, <<"from">>);
	    _ ->
		    set_sender(S1, To)
    end.


%% @spec (Stanza) -> Stanza_Reply
%%     Stanza = exml:xmlel()
%%     Stanza_Reply = exml:xmlel()
%% @doc Prepare a reply to `Stanza' with children removed.
%%

-spec(reply_without_content/1 :: (exml:xmlel()) -> exml:xmlel()).

reply_without_content(Stanza) ->
    {xmlel, Name, Attrs, _} = reply(Stanza),
    {xmlel, Name, Attrs, []}.


%% @spec (Stanza, Error) -> Stanza_Reply
%%     Stanza = exml:xmlel()
%%     Error = exml:xmlel() | binary()
%%     Stanza_Reply = exml:xmlel()
%% @doc Prepare an error reply to `Stanza'.
%%
%% If `Error' is an atom, it must be a standard condition defined by
%% XMPP Core.

-spec(reply_with_error/2 :: (exml:xmlel(), exml:xmlel() | binary()) -> exml:xmlel()).

reply_with_error(Stanza, Condition) when is_binary(Condition) ->
    Error = exmpp_staza:error(Condition),
    reply_with_error(Stanza, Error);
reply_with_error(Stanza, Error) ->
    Reply = reply(Stanza),
    stanza_error(Reply, Error).

%% --------------------------------------------------------------------
%% Stanza-level errors.
%% --------------------------------------------------------------------

standard_conditions() ->
    [
     {<<"bad-request">>,             <<"modify">> },
     {<<"conflict">>,                <<"cancel">> },
     {<<"feature-not-implemented">>, <<"cancel">> },
     {<<"forbidden">>,               <<"auth">>   },
     {<<"gone">>,                    <<"modify">> },
     {<<"internal-server-error">>,   <<"wait">>   },
     {<<"item-not-found">>,          <<"cancel">> },
     {<<"jid-malformed">>,           <<"modify">> },
     {<<"not-acceptable">>,          <<"modify">> },
     {<<"not-allowed">>,             <<"cancel">> },
     {<<"not-authorized">>,          <<"auth">>   },
     {<<"payment-required">>,        <<"auth">>   },
     {<<"recipient-unavailable">>,   <<"wait">>   },
     {<<"redirect">>,                <<"modify">> },
     {<<"registration-required">>,   <<"auth">>   },
     {<<"remote-server-not-found">>, <<"cancel">> },
     {<<"remote-server-timeout">>,   <<"wait">>   },
     {<<"resource-constraint">>,     <<"wait">>   },
     {<<"service-unavailable">>,     <<"cancel">> },
     {<<"subscription-required">>,   <<"auth">>   },
     {<<"unexpected-request">>,      <<"wait">>   },
     {<<"undefined-condition">>,     undefined}
    ].

%% @spec (Condition) -> Stanza_Error
%%     Condition = binary()
%%     Stanza_Error = exml:xmlel()
%% @doc Create an `<error/>' element based on the given `Condition'.
%%
-spec(error/1 :: (binary()) -> exml:xmlel()).

error(Condition) ->
    error(Condition, {undefined, undefined}).

%% @spec (Condition, Text_Spec) -> Stanza_Error
%%     Condition = binary()
%%     Text_Spec = {Lang, Text} | Text | undefined
%%     Lang = binary() | | undefined
%%     Text = binary() | | undefined
%%     Stanza_Error = exml:xmlel()
%% @doc Create an `<error/>' element based on the given `Condition'.
%%

-spec(error/2 ::
	(binary(), {lang(), binary() | undefined}) -> exml:xmlel()).

error(Condition, {Lang, Text}) ->
    Condition_El = {xmlel, Condition, [{<<"xmlns">>, ?NS_STANZA_ERRORS}], []},
    Error_El0 = {xmlel, <<"error">>, [], [Condition_El]},
    Error_El = case Text of
		   undefined ->
		       Error_El0;
		   _ ->
		   	Text_El0 = {xmlel, <<"text">>, [{<<"xmlns">>, ?NS_STANZA_ERRORS}], [{cdata, Text}]},
            		Text_El = case Lang of
                	undefined ->
                    		Text_El0;
                	_ ->
                    		exml:set_attribute(Text_El0, <<"xml:lang">>, Lang)
		       end,
            	       exml:append_child(Error_El0, Text_El)
    end,
    set_error_type_from_condition_in_error(Error_El, Condition);
error(Condition, Text) ->
    error(Condition, {undefined, Text}).

%% @spec (Stanza, Error) -> Stanza_Error
%%     Stanza = exml:xmlel()
%%     Error = exml:xmlel()
%%     Stanza_Error = exml:xmlel()
%% @doc Transform `Stanza' in a stanza error.
%%
%% The `type' attribute is set and an error condition is added. The
%% caller is still responsible to set or modify the `to' attribute
%% correctly.
%%
%% @see error/2.
%% @see error/3.

-spec(stanza_error/2 :: (exml:xmlel(), exml:xmlel()) -> exml:xmlel()).

stanza_error(Stanza, Error) ->
    Stanza_Error = exml:append_child(Stanza, Error),
    set_type(Stanza_Error, <<"error">>).

%% @spec (Stanza, Error) -> Stanza_Error
%%     Stanza = exmpp_xml:xmlel()
%%     Error = exmpp_xml:xmlel()
%%     Stanza_Error = exmpp_xml:xmlel()
%% @doc Transform `Stanza' in a stanza error.
%%
%% Previous child elements from `Stanza' are not kept.
%%
%% @see stanza_error/2.

-spec(stanza_error_without_original/2 :: (#xmlel{}, #xmlel{}) -> #xmlel{}).

stanza_error_without_original(Stanza, Error) ->
    Stanza_Error = exmpp_xml:set_children(Stanza, [Error]),
    set_type(Stanza_Error, "error").

%% @spec (Stanza) -> bool()
%%     Stanza = exmpp_xml:xmlel()
%% @doc Tell if the stanza transports an error.

-spec(is_stanza_error/1 :: (#xmlel{}) -> boolean()).

is_stanza_error(Stanza) ->
    case get_type(Stanza) of
        <<"error">> -> true;
        _           -> false
    end.

%% @spec (Stanza) -> Type
%%     Stanza = exmpp_xml:xmlel()
%%     Type = binary()
%% @throws {stanza_error, error_type, no_error_element_found, Stanza}
%% @doc Return the type of the error element.

-spec(get_error_type/1 :: (#xmlel{}) -> binary()).

get_error_type(Stanza) ->
    case get_error(Stanza) of
        undefined ->
            throw({stanza_error, error_type, no_error_element_found, Stanza});
        Error ->
            get_error_type_from_error(Error)
    end.

get_error_type_from_error(Error) ->
    exmpp_xml:get_attribute_as_binary(Error, <<"type">>, <<>>).

%% @spec (Stanza, Type) -> New_Stanza
%%     Stanza = exmpp_xml:xmlel()
%%     Type = binary() | string()
%%     New_Stanza = exmpp_xml:xmlel()
%% @throws {stanza_error, error_type, no_error_element_found, Stanza}
%% @doc Set the type of the error element.

-spec(set_error_type/2 :: (#xmlel{}, binary()) -> #xmlel{}).

set_error_type(Stanza, Type) ->
    case get_error(Stanza) of
        undefined ->
            throw({stanza_error, error_type, no_error_element_found, Stanza});
        Error ->
            New_Error = set_error_type_in_error(Error, Type),
            exmpp_xml:replace_child(Stanza, Error, New_Error)
    end.

set_error_type_in_error(Error, Type) ->
    exml:set_attribute(Error, <<"type">>, Type).

%% @spec (Stanza, Condition) -> New_Stanza
%%     Stanza = exmpp_xml:xmlel()
%%     Condition = atom()
%%     New_Stanza = exmpp_xml:xmlel()
%% @throws {stanza_error, error_type, no_error_element_found, Stanza} |
%%         {stanza_error, error_type, invalid_condition, {NS, Condition}}
%% @doc Set the type of the error element, based on the given condition.
%%
%% If the condition is `undefined-condition', the type is unchanged.

-spec(set_error_type_from_condition/2 :: (#xmlel{}, atom()) -> #xmlel{}).

set_error_type_from_condition(Stanza, Condition) ->
    case get_error(Stanza) of
        undefined ->
            throw({stanza_error, error_type, no_error_element_found, Stanza});
        Error ->
            New_Error = set_error_type_from_condition_in_error(Error,
              Condition),
            exmpp_xml:replace_child(Stanza, Error, New_Error)
    end.

set_error_type_from_condition_in_error(Error, Condition) ->
    case lists:keysearch(Condition, 1, standard_conditions()) of
        {value, {_, undefined}} ->
            Error;
        {value, {_, Type}} ->
            set_error_type_in_error(Error, Type);
        false ->
            throw({stanza_error, error_type, invalid_condition, Condition})
    end.

%% @spec (Stanza) -> Condition | undefined
%%     Stanza = exml:xmlel()
%%     Condition = binary()
%% @throws {stanza_error, condition, no_error_element_found, Stanza} |
%%         {stanza_error, condition, no_condition_found, Error}
%% @doc Return the child element name corresponding to the stanza error
%% condition.
%%

-spec(get_condition/1 :: (exml:xmlel()) -> binary()).

get_condition(Stanza) ->
    case get_error(Stanza) of
        undefined ->
            throw({stanza_error, condition, no_error_element_found, Stanza});
        Error ->
            get_condition_in_error(Error)
    end.

get_condition_in_error({xmlel, _Name, _Attrs, _Children} = Error)  ->
	case exml:get_child_elements(Error) of
		[{xmlel, Condition, _Attrs2, _C}|_] when Condition /= <<"text">> ->
			Condition;
		_ ->
            	% This <error/> element is invalid because the condition must be
	         % present (and first).
        	    throw({stanza_error, condition, no_condition_found, Error})
        end.

%% @spec (Stanza) -> Text | undefined
%%     Stanza = exml:xmlel()
%%     Text = binary()
%% @throws {stanza_error, text, no_error_element_found, Stanza}
%% @doc Return the text that describes the error.
%%
%% If there is no `<text/>' element, an empty string is returned.

-spec(get_text/1 :: (exml:xmlel()) -> binary()).

get_text(Stanza) ->
    case get_error(Stanza) of
        undefined ->
            throw({stanza_error, text, no_error_element_found, Stanza});
        Error ->
            get_text_in_error(Error)
    end.

get_text_in_error(Error) ->
	exml:get_path(Error, [{element, <<"text">>}, cdata]).

%% --------------------------------------------------------------------
%% Serialization wrappers.
%% --------------------------------------------------------------------

%% @spec (El, Default_NS) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     Default_NS = NS | Equivalent_NSs
%%     NS = atom() | string()
%%     Equivalent_NSs = [NS]
%%     XML_Text = string()
%% @doc Serialize a stanza using the given default namespace.
%%
%% The XMPP namespace `http://etherx.jabber.org/streams' and the
%% Server Dialback `jabber:server:dialback' are included as a prefixed
%% namespace, with the `stream' prefix.

-spec(to_list/2 ::
  (#xmlel{} | #iq{} | #xmlendtag{}, xmldefaultns()) -> string()).

to_list(El, Default_NS) ->
    to_list(El, Default_NS,
      [{?NS_XMPP, ?NS_XMPP_pfx}, {?NS_DIALBACK, ?NS_DIALBACK_pfx}]).

%% @spec (El, Default_NS, Prefix) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     Default_NS = [NS]
%%     Prefixed_NS = [{NS, Prefix}]
%%     NS = atom() | string()
%%     Prefix = string()
%%     XML_Text = string()
%% @doc Serialize a stanza using the given namespaces.
%%
%% To understand `Default_NS', see {@link exmpp_xml:xmlel_to_xmlelement/3}.

-spec(to_list/3 ::
  (#xmlel{} | #iq{} | #xmlendtag{}, xmldefaultns(), xmlprefixednss()) -> string()).

to_list(#iq{} = El, Default_NS, Prefixed_NS) ->
    to_list(exmpp_iq:iq_to_xmlel(El), Default_NS, Prefixed_NS);
to_list(El, Default_NS, Prefixed_NS) ->
    exmpp_xml:node_to_list(El, [Default_NS], Prefixed_NS).

%% @spec (El) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     XML_Text = string()
%% @doc Serialize a stanza using common XMPP default namespaces.
%%
%% This function calls {@link to_list/2} with `Default_NS' set to
%% `[?NS_JABBER_CLIENT, ?NS_JABBER_SERVER, ?NS_COMPONENT_ACCEPT,
%% ?NS_COMPONENT_CONNECT]'.

-spec(to_list/1 :: (#xmlel{} | #iq{} | #xmlendtag{}) -> string()).

to_list(El) ->
    to_list(El, [
        ?NS_JABBER_CLIENT,
        ?NS_JABBER_SERVER,
        ?NS_COMPONENT_ACCEPT,
        ?NS_COMPONENT_CONNECT
      ]).

%% @spec (El, Default_NS) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     Default_NS = NS | Equivalent_NSs
%%     NS = atom() | string()
%%     Equivalent_NSs = [NS]
%%     XML_Text = binary()
%% @doc Serialize a stanza using the given default namespace.
%%
%% The XMPP namespace `http://etherx.jabber.org/streams' and the
%% Server Dialback `jabber:server:dialback' are included as a prefixed
%% namespace, with the `stream' prefix.

-spec(to_binary/2 ::
  (#xmlel{} | #iq{}| #xmlendtag{}, xmldefaultns()) -> binary()).

to_binary(El, Default_NS) ->
    to_binary(El, Default_NS,
      [{?NS_XMPP, ?NS_XMPP_pfx}, {?NS_DIALBACK, ?NS_DIALBACK_pfx}]).

%% @spec (El, Default_NS, Prefix) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     Default_NS = [NS]
%%     Prefixed_NS = [{NS, Prefix}]
%%     NS = atom() | string()
%%     Prefix = string()
%%     XML_Text = binary()
%% @doc Serialize a stanza using the given namespaces.
%%
%% To understand `Default_NS', see {@link exmpp_xml:xmlel_to_xmlelement/3}.

-spec(to_binary/3 ::
  (#xmlel{} | #iq{}| #xmlendtag{}, xmldefaultns(), xmlprefixednss()) -> binary()).

to_binary(#iq{} = El, Default_NS, Prefixed_NS) ->
    to_binary(exmpp_iq:iq_to_xmlel(El), Default_NS, Prefixed_NS);
to_binary(El, Default_NS, Prefixed_NS) ->
    exmpp_xml:node_to_binary(El, [Default_NS], Prefixed_NS).

%% @spec (El) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     XML_Text = binary()
%% @doc Serialize a stanza using common XMPP default namespaces.
%%
%% This function calls {@link to_binary/2} with `Default_NS' set to
%% `[?NS_JABBER_CLIENT, ?NS_JABBER_SERVER, ?NS_COMPONENT_ACCEPT,
%% ?NS_COMPONENT_CONNECT]'.

-spec(to_binary/1 :: (#xmlel{} | #iq{}| #xmlendtag{}) -> binary()).

to_binary(El) ->
    to_binary(El, [
        ?NS_JABBER_CLIENT,
        ?NS_JABBER_SERVER,
        ?NS_COMPONENT_ACCEPT,
        ?NS_COMPONENT_CONNECT
      ]).

%% @spec (El, Default_NS) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     Default_NS = NS | Equivalent_NSs
%%     NS = atom() | string()
%%     Equivalent_NSs = [NS]
%%     XML_Text = iolist()
%% @doc Serialize a stanza using the given default namespace.
%%
%% The XMPP namespace `http://etherx.jabber.org/streams' and the
%% Server Dialback `jabber:server:dialback' are included as a prefixed
%% namespace, with the `stream' prefix.

-spec(to_iolist/2 ::
  (#xmlel{} | #iq{}| #xmlendtag{}, xmldefaultns()) -> iolist()).

to_iolist(El, Default_NS) ->
    to_iolist(El, Default_NS,
      [{?NS_XMPP, ?NS_XMPP_pfx}, {?NS_DIALBACK, ?NS_DIALBACK_pfx}]).

%% @spec (El, Default_NS, Prefix) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     Default_NS = [NS]
%%     Prefixed_NS = [{NS, Prefix}]
%%     NS = atom() | string()
%%     Prefix = string()
%%     XML_Text = iolist()
%% @doc Serialize a stanza using the given namespaces.
%%
%% To understand `Default_NS', see {@link exmpp_xml:xmlel_to_xmlelement/3}.

-spec(to_iolist/3 ::
  (#xmlel{} | #iq{}| #xmlendtag{}, xmldefaultns(), xmlprefixednss()) -> iolist()).

to_iolist(#iq{} = El, Default_NS, Prefixed_NS) ->
    to_iolist(exmpp_iq:iq_to_xmlel(El), Default_NS, Prefixed_NS);
to_iolist(El, Default_NS, Prefixed_NS) ->
    exmpp_xml:node_to_iolist(El, [Default_NS], Prefixed_NS).

%% @spec (El) -> XML_Text
%%     El = exmpp_xml:xmlel() | exmpp_iq:iq() | list()
%%     XML_Text = iolist()
%% @doc Serialize a stanza using common XMPP default namespaces.
%%
%% This function calls {@link to_iolist/2} with `Default_NS' set to
%% `[?NS_JABBER_CLIENT, ?NS_JABBER_SERVER, ?NS_COMPONENT_ACCEPT,
%% ?NS_COMPONENT_CONNECT]'.

-spec(to_iolist/1 :: (#xmlel{} | #iq{}| #xmlendtag{}) -> iolist()).

to_iolist(El) ->
    to_iolist(El, [
        ?NS_JABBER_CLIENT,
        ?NS_JABBER_SERVER,
        ?NS_COMPONENT_ACCEPT,
        ?NS_COMPONENT_CONNECT
      ]).
