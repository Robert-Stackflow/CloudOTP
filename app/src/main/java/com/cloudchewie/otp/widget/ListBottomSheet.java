package com.cloudchewie.otp.widget;

import android.content.Context;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.adapter.ListBottomSheetAdapter;
import com.cloudchewie.otp.entity.ListBottomSheetBean;
import com.cloudchewie.otp.util.decoration.DividerItemDecoration;
import com.cloudchewie.ui.general.BottomSheet;

import java.util.List;

public class ListBottomSheet extends BottomSheet {
    List<ListBottomSheetBean> beanList;
    int checkedIndex = -1;
    boolean checkable;
    RecyclerView recyclerView;
    ListBottomSheetAdapter adapter;
    TextView cancelButton;
    OnCancelListener onCancelListener;
    OnItemClickedListener listener;

    public ListBottomSheet(@NonNull Context context, List<ListBottomSheetBean> beanList) {
        super(context);
        this.beanList = beanList;
        initView();
    }

    public ListBottomSheet(@NonNull Context context, List<ListBottomSheetBean> beanList, boolean checkable, int checkedIndex) {
        super(context);
        this.beanList = beanList;
        this.checkable = checkable;
        this.checkedIndex = checkedIndex;
        initView();
    }

    public ListBottomSheet setOnCancelListener(OnCancelListener onCancelListener) {
        this.onCancelListener = onCancelListener;
        return this;
    }

    void initView() {
        setBackGroundTint(R.color.card_background);
        setTitleBarBackGroundTint(R.color.content_background);
        setMainLayout(R.layout.layout_list_bottom_sheet);
        recyclerView = mainView.findViewById(R.id.layout_list_bottom_sheet_recyclerview);
        cancelButton = mainView.findViewById(R.id.layout_list_bottom_sheet_cancel);
        cancelButton.setOnClickListener(v -> {
            if (onCancelListener != null) onCancelListener.OnCancle();
            dismiss();
        });
        adapter = new ListBottomSheetAdapter(getContext(), beanList);
        adapter.setCheckable(checkable);
        adapter.setCheckIndex(checkedIndex);
        recyclerView.setAdapter(adapter);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        recyclerView.addItemDecoration(new DividerItemDecoration(getContext(), DividerItemDecoration.VERTICAL));
        recyclerView.setOverScrollMode(View.OVER_SCROLL_NEVER);
    }

    public ListBottomSheet setOnItemClickedListener(OnItemClickedListener onItemClickedListener) {
        this.listener = position -> {
            onItemClickedListener.onItemClicked(position);
            if (checkable) {
                for (int i = 0; i < adapter.getItemCount(); i++) {
                    ListBottomSheetAdapter.MyViewHolder myViewHolder = (ListBottomSheetAdapter.MyViewHolder) recyclerView.findViewHolderForAdapterPosition(i);
                    if (i != position) myViewHolder.checkView.setVisibility(View.GONE);
                    else myViewHolder.checkView.setVisibility(View.VISIBLE);
                }
            }
        };
        if (adapter != null) adapter.setOnItemClickedListener(listener);
        return this;
    }

    public interface OnCancelListener {
        void OnCancle();
    }

    public interface OnItemClickedListener {
        void onItemClicked(int position);
    }
}
