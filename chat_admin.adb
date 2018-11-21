with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Chat_Messages;
with Ada.Command_Line;
with Client_Collections;

procedure Chat_Admin is
	package LLU renames Lower_Layer_UDP;
	package ATIO renames Ada.Text_IO;
   package ASU renames Ada.Strings.Unbounded;
	package ACL renames Ada.Command_Line;
	package CM renames Chat_Messages;
	package CC renames Client_Collections;
	use type CM.Message_Type;
	use type ASU.Unbounded_String;

	Usage_Error: exception;

	Server_EP: LLU.End_Point_Type;
   Admin_EP: LLU.End_Point_Type;
   Buffer: aliased LLU.Buffer_Type(1024);
	Maquina: ASU.Unbounded_String;
	Puerto: Integer;
	Password: ASU.Unbounded_String;
	Expired: Boolean;
	Nick: ASU.Unbounded_String;
	Collection: ASU.Unbounded_String;
	Option: ASU.Unbounded_String;
	Finish: Boolean;	
	Mess: CM.Message_Type;
   Reply: ASU.Unbounded_String;

begin
	if ACL.Argument_Count = 3 then
		Maquina := ASU.To_Unbounded_String(ACL.Argument(1));
		Puerto := Integer'Value(ACL.Argument(2));
		Password := ASU.To_Unbounded_String(ACL.Argument(3));
		Server_EP := LLU.Build (LLU.To_IP(ACL.Argument(1)), Puerto);
	   LLU.Bind_Any(Admin_EP);
		Finish := False;
		while not Finish loop
			ATIO.New_Line;
			ATIO.Put_Line("Options");
			ATIO.Put_Line("1 Show writers collection");
			ATIO.Put_Line("2 Ban writer");
			ATIO.Put_Line("3 Shutdown server");
			ATIO.Put_Line("4 Quit");
			ATIO.New_Line;
			ATIO.Put("Your option? ");
			Option := ASU.To_Unbounded_String(ATIO.Get_Line);
			ATIO.New_Line;
			if Option = "1" then
				LLU.Reset(Buffer);
				Mess := CM.Collection_Request;
				CM.Message_Type'Output(Buffer'Access, Mess);
				LLU.End_Point_Type'Output(Buffer'Access, Admin_EP);
				ASU.Unbounded_String'Output(Buffer'Access, Password);
				LLU.Send(Server_EP, Buffer'Access);
				LLU.Receive(Admin_EP, Buffer'Access, 1000.0, Expired);
				if Expired then
					Ada.Text_IO.Put_Line ("Plazo expirado");
				else
					Mess := CM.Message_Type'Input(Buffer'Access);
					Collection := ASU.Unbounded_String'Input(Buffer'Access);
					ATIO.Put_Line(ASU.To_String(Collection));
					if Collection = "" then
						ATIO.Put_Line("No clients.");
					end if;
				end if;
			elsif Option = "2" then
				ATIO.Put("Nick to ban? ");
				Nick := ASU.To_Unbounded_String(ATIO.Get_Line);
				LLU.Reset(Buffer);
				Mess := CM.Ban;
				CM.Message_Type'Output(Buffer'Access, Mess);
				ASU.Unbounded_String'Output(Buffer'Access, Password);
				ASU.Unbounded_String'Output(Buffer'Access, Nick);
				LLU.Send(Server_EP, Buffer'Access);
			elsif Option = "3" then
				LLU.Reset(Buffer);
				Mess := CM.Shutdown;
				CM.Message_Type'Output(Buffer'Access, Mess);
				ASU.Unbounded_String'Output(Buffer'Access, Password);
				LLU.Send(Server_EP, Buffer'Access);
			elsif Option = "4" then
				LLU.Finalize;
				Finish := True;
			else
				ATIO.Put_Line("Incorrect option. Try again.");
			end if;
		end loop;
	else
		ATIO.Put_Line("usage");
		raise Usage_Error;
	end if;
	LLU.Finalize;
exception

   when Usage_Error =>
		ATIO.Put_Line("usage: chat_admin nombre_maquina puerto password");
		LLU.Finalize;
end Chat_Admin;
