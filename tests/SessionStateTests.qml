import QtQuick
import "../caelestia/modules/session"
Item {
 SessionActionState { id: state }
 property int requests: 0
 Connections { target: state; function onExecuteRequested(command) { requests++; } }
 function check(value,why) { if(!value)throw new Error(why); }
 Component.onCompleted: {
  try {
   for (var kind of ["logout","switchDesktop","shutdown","restart","hibernate"]) {
    state.cancel();state.request(kind);check(state.pending===kind&&!state.busy,"confirm "+kind);state.request(kind);check(state.busy,"dispatch "+kind);state.request(kind);state.complete(1,"failure");check(!state.busy&&state.feedback.includes("failure"),"failure "+kind);
   }
   state.request("switchDesktop");state.request("switchDesktop");state.complete(2,"");check(state.canForce,"force offered");state.request("force");check(!state.busy,"force confirmation");state.request("force");state.complete(0,"");
   check(JSON.stringify(state.commandFor("shutdown"))==='["systemctl","poweroff"]',"power command");
   check(JSON.stringify(state.commandFor("switchDesktop"))==='["multienv-logout","--greeter"]',"switch command");
   console.log("STATE_TEST_OK",requests);Qt.quit();
  } catch(error) { console.error("STATE_TEST_FAILED",error);Qt.quit(); }
 }
}