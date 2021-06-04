;Warning, spanish code below
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance Force

salidas := ArmarListaSalidaAudio()
FileRead, excepcionesString, Excepciones.txt
excepciones := StrSplit(excepcionesString,"`n")


#If (!ExepcionAbierta(excepciones))
XButton1::
{
	KeyWait, XButton1
    send, {Browser_Back}
	return
}

XButton2::
{
	KeyWait, XButton2
    send, {Browser_Forward}
    return
}


F13::send, {Ctrl Down}w{Ctrl Up}
XButton1 & XButton2::send, ^t
XButton1 & WheelDown::send, {WheelDown 5}
XButton1 & WheelUp::send, {WheelUp 5}
XButton1 & LButton::send, ^+{Tab}			;Para una mejor experiencia configurar el navegador a no cambiar entre pestañas segun ultima visita
XButton1 & RButton::send, ^{Tab}
XButton1 & MButton::CambiarSalidaAudio(salidas,2)
XButton1 & F13::send, ^+t  				;El boton "cambio de sensibilidad" está configurado a F13 en el panel de mi mouse logitech

XButton2 & XButton1::send, {f5}
XButton2 & WheelDown::send, {Volume_Down}
XButton2 & WheelUp::send, {Volume_Up}
XButton2 & LButton::send, {Left}
XButton2 & RButton::send, {Right}
XButton2 & MButton::CambiarSalidaAudio(salidas,1)
XButton2 & F13::
{
    send, {Alt Down}{tab}
    KeyWait, XButton2
    send, {Alt Up}
    return
}

F13 & MButton::
{   
    if(A_ThisHotkey == "F13 & MButton")
    {
        SoundPlay, *64
        WinGetActiveTitle, titulo
        FileAppend,`n%titulo%, excepciones.txt
        Reload
    }
    return
}

;Warning, stolen code below
ArmarListaSalidaAudio()
{
; http://www.daveamenta.com/2011-05/programmatically-or-command-line-change-the-default-sound-playback-device-in-windows-7/
Devices := {}
IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")

; IMMDeviceEnumerator::EnumAudioEndpoints
; eRender = 0, eCapture, eAll
; 0x1 = DEVICE_STATE_ACTIVE
DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+3*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 0x1, "UPtrP", IMMDeviceCollection, "UInt")
ObjRelease(IMMDeviceEnumerator)

; IMMDeviceCollection::GetCount
DllCall(NumGet(NumGet(IMMDeviceCollection+0)+3*A_PtrSize), "UPtr", IMMDeviceCollection, "UIntP", Count, "UInt")
Loop % (Count)
{
    ; IMMDeviceCollection::Item
    DllCall(NumGet(NumGet(IMMDeviceCollection+0)+4*A_PtrSize), "UPtr", IMMDeviceCollection, "UInt", A_Index-1, "UPtrP", IMMDevice, "UInt")

    ; IMMDevice::GetId
    DllCall(NumGet(NumGet(IMMDevice+0)+5*A_PtrSize), "UPtr", IMMDevice, "UPtrP", pBuffer, "UInt")
    DeviceID := StrGet(pBuffer, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "UPtr", pBuffer)

    ; IMMDevice::OpenPropertyStore
    ; 0x0 = STGM_READ
    DllCall(NumGet(NumGet(IMMDevice+0)+4*A_PtrSize), "UPtr", IMMDevice, "UInt", 0x0, "UPtrP", IPropertyStore, "UInt")
    ObjRelease(IMMDevice)

    ; IPropertyStore::GetValue
    VarSetCapacity(PROPVARIANT, A_PtrSize == 4 ? 16 : 24)
    VarSetCapacity(PROPERTYKEY, 20)
    DllCall("Ole32.dll\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "UPtr", &PROPERTYKEY)
    NumPut(14, &PROPERTYKEY + 16, "UInt")
    DllCall(NumGet(NumGet(IPropertyStore+0)+5*A_PtrSize), "UPtr", IPropertyStore, "UPtr", &PROPERTYKEY, "UPtr", &PROPVARIANT, "UInt")
    DeviceName := StrGet(NumGet(&PROPVARIANT + 8), "UTF-16")    ; LPWSTR PROPVARIANT.pwszVal
    DllCall("Ole32.dll\CoTaskMemFree", "UPtr", NumGet(&PROPVARIANT + 8))    ; LPWSTR PROPVARIANT.pwszVal
    ObjRelease(IPropertyStore)

    ObjRawSet(Devices, DeviceName, DeviceID)
}
ObjRelease(IMMDeviceCollection)


Devices2 := {}
For DeviceName, DeviceID in Devices
    List .= "(" . A_Index . ") " . DeviceName . "`n", ObjRawSet(Devices2, A_Index, DeviceID)

return Devices2
}

CambiarSalidaAudio(Devices2,n)
{ 
	;IPolicyConfig::SetDefaultEndpoint
	IPolicyConfig := ComObjCreate("{870af99c-171d-4f9e-af0d-e63df40c2bc9}", "{F8679F50-850A-41CF-9C72-430F290290C8}") ;00000102-0000-0000-C000-000000000046 00000000-0000-0000-C000-000000000046
	R := DllCall(NumGet(NumGet(IPolicyConfig+0)+13*A_PtrSize), "UPtr", IPolicyConfig, "Str", Devices2[n], "UInt", 0, "UInt")
	ObjRelease(IPolicyConfig)
    
    SoundPlay, beep.mp3
}

ExepcionAbierta(excep) 
{
    WinGetActiveTitle, titulo
    for index, value in excep
        if (value = titulo)
            return 1
    if !(IsObject(excep))
        throw Exception("Bad haystack!", -1, haystack)
    return 0
}
