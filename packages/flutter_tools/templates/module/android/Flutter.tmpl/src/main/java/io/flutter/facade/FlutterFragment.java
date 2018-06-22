package io.flutter.facade;

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

/**
 * A {@link Fragment} managing a Flutter view.
 *
 * <p><strong>Warning:</strong> This file is auto-generated by Flutter tooling. Do not edit.
 * It may be moved into flutter.jar or another library dependency of the Flutter module project
 * at a later point.</p>
 */
public class FlutterFragment extends Fragment {
  public static final String ARG_ROUTE = "route";
  private String mRoute = "/";

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    if (getArguments() != null) {
      mRoute = getArguments().getString(ARG_ROUTE);
    }
  }

  @Override
  public void onInflate(Context context, AttributeSet attrs, Bundle savedInstanceState) {
    super.onInflate(context, attrs, savedInstanceState);
  }

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container,
                           Bundle savedInstanceState) {
    return Flutter.createView(getActivity(), getLifecycle(), mRoute);
  }
}
